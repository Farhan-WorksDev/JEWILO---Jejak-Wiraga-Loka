import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../ui/state/app_state.dart';
import 'frame_buffer.dart';
import 'landmark_extractor.dart';
import 'pose_match.dart';

/// Service orkestrasi: kamera + MediaPipe native (+ TFLite opsional).
///
/// PENTING: kamera TIDAK lagi dinyalakan di main(). Panggil [start] saat
/// masuk layar latihan dan [stop] saat keluar, supaya layar lain tidak
/// ikut berat.
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  /// Kalau ternyata skeleton live kebalik kiri-kanan di layar, ubah ke true.
  static const bool nativeAlreadyMirrored = false;

  CameraController? _camera;
  Interpreter? _interpreter;
  LandmarkExtractor? _extractor;
  final FrameBuffer _buffer = FrameBuffer(windowSize: 60, featureSize: 300);

  Map<String, int> _labelIndex = const {'bukan_saman': 0, 'tari_saman': 1};

  /// Probabilitas "ini Tari Saman" dari classifier (hanya kalau diaktifkan).
  final ValueNotifier<double> accuracy = ValueNotifier<double>(0);
  final ValueNotifier<int> frameCount = ValueNotifier<int>(0);
  final ValueNotifier<String?> status = ValueNotifier<String?>(null);

  /// Landmark terbaru (null = tidak ada orang terdeteksi).
  final ValueNotifier<PoseFrame?> pose = ValueNotifier<PoseFrame?>(null);

  /// FPS deteksi yang benar-benar tercapai.
  final ValueNotifier<int> detectFps = ValueNotifier<int>(0);

  /// true kalau kamera + model siap dipakai.
  final ValueNotifier<bool> readyNotifier = ValueNotifier<bool>(false);

  /// Classifier Saman/bukan Saman (LSTM) berat. Matikan kecuali dibutuhkan.
  bool classifierEnabled = false;

  Future<void>? _startFuture;
  bool _ready = false;
  bool _extracting = false;
  bool _inferring = false;
  String? _error;
  int _rotation = 0;
  bool _front = true;
  int _lastFrameMs = 0;
  int _fpsWindowStart = 0;
  int _fpsCount = 0;
  int _sinceInference = 0;

  bool get ready => _ready;
  String? get error => _error;
  int get numClasses => _labelIndex.length;
  CameraController? get camera => _camera;

  /// Perlu dicerminkan agar sama dengan preview kamera depan.
  bool get mirror => _front && !nativeAlreadyMirrored;

  /// Ukuran frame setelah ditegakkan (dipakai untuk menggambar skeleton).
  Size get uprightSize {
    final ps = _camera?.value.previewSize;
    if (ps == null) return const Size(480, 640);
    return (_rotation == 90 || _rotation == 270)
        ? Size(ps.height, ps.width)
        : Size(ps.width, ps.height);
  }

  Future<void> start() {
    if (_ready) return Future.value();
    return _startFuture ??= _start().whenComplete(() => _startFuture = null);
  }

  Future<void> _start() async {
    _error = null;
    status.value = null;
    try {
      final perm = await Permission.camera.request();
      if (!perm.isGranted) {
        _fail('Izin kamera ditolak. Aktifkan lewat Pengaturan HP.');
        return;
      }

      final cams = await availableCameras();
      if (cams.isEmpty) {
        _fail('Kamera tidak tersedia.');
        return;
      }
      final cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      _front = cam.lensDirection == CameraLensDirection.front;
      // HP portrait: gambar harus diputar sebesar sensorOrientation
      // supaya orangnya tegak waktu masuk ke MediaPipe.
      _rotation = cam.sensorOrientation;

      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await ctrl.initialize();
      try {
        await ctrl.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {}
      _camera = ctrl;

      if (classifierEnabled) {
        try {
          final raw = await rootBundle.loadString(
            'assets/models/label_map.json',
          );
          final map = jsonDecode(raw);
          if (map is Map) {
            _labelIndex = map.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            );
          }
        } catch (_) {}
        try {
          _interpreter = await Interpreter.fromAsset(
            'assets/models/dance_detector.tflite',
          );
        } catch (e) {
          debugPrint('Model TFLite gagal dimuat: $e');
          classifierEnabled = false;
        }
      }

      _extractor = MediaPipeHolisticExtractor();
      try {
        await _extractor!.initialize(modelPath: 'holistic_landmarker.task');
      } catch (e) {
        await _camera?.dispose();
        _camera = null;
        _fail('Holistic extractor gagal init: $e');
        return;
      }

      _buffer.clear();
      await ctrl.startImageStream(_onFrame);
      _ready = true;
      readyNotifier.value = true;
      status.value = 'Kamera & model siap.';
    } catch (e) {
      _fail('Inisialisasi gagal: $e');
    }
  }

  void _fail(String msg) {
    _error = msg;
    status.value = msg;
    readyNotifier.value = false;
  }

  void _onFrame(CameraImage image) {
    if (!_ready || _extracting) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final fps = AppState.instance.fps.clamp(5, 30).toInt();
    if (now - _lastFrameMs < 1000 ~/ fps) return;
    _lastFrameMs = now;
    _extracting = true;

    _extractor
        ?.extract(image, rotation: _rotation)
        .then((lm) {
          if (!_ready) return;
          if (lm == null) {
            pose.value = null;
            return;
          }
          pose.value = PoseFrame(lm, now);

          _fpsCount++;
          if (now - _fpsWindowStart >= 1000) {
            detectFps.value = _fpsCount;
            _fpsCount = 0;
            _fpsWindowStart = now;
          }

          if (classifierEnabled && _interpreter != null) {
            try {
              _buffer.push(lm);
            } catch (_) {
              return;
            }
            frameCount.value = _buffer.length;
            _sinceInference++;
            if (_buffer.isFull && _sinceInference >= 10) {
              _sinceInference = 0;
              _runInference();
            }
          }
        })
        .catchError((Object e) {
          debugPrint('Extract error: $e');
        })
        .whenComplete(() => _extracting = false);
  }

  Future<void> _runInference() async {
    final interp = _interpreter;
    if (interp == null || _inferring) return;
    _inferring = true;
    try {
      final input = _buffer.asTensor();
      final n = numClasses;
      final output = List.generate(1, (_) => List<double>.filled(n, 0));
      interp.run(input, output);
      final samanIdx = _labelIndex['tari_saman'] ?? 1;
      final prob = output[0][samanIdx].clamp(0.0, 1.0);
      accuracy.value = (prob * 100).clamp(0, 100).toDouble();
    } catch (e) {
      debugPrint('Inference error: $e');
    } finally {
      _inferring = false;
    }
  }

  /// Matikan kamera & model. Aman dipanggil berkali-kali.
  Future<void> stop() async {
    try {
      await _startFuture;
    } catch (_) {}
    _ready = false;
    readyNotifier.value = false;
    final cam = _camera;
    _camera = null;
    try {
      if (cam != null && cam.value.isStreamingImages) {
        await cam.stopImageStream();
      }
    } catch (_) {}
    try {
      await cam?.dispose();
    } catch (_) {}
    _interpreter?.close();
    _interpreter = null;
    try {
      await _extractor?.dispose();
    } catch (_) {}
    _extractor = null;
    _buffer.clear();
    pose.value = null;
    detectFps.value = 0;
    _extracting = false;
    _inferring = false;
  }
}
