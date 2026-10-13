import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'frame_buffer.dart';
import 'landmark_extractor.dart';

/// Service orkestrasi: kamera + MediaPipe native + TFLite.
///
/// Semua offline:
///  - Model TFLite dari assets/models/dance_detector.tflite
///  - Holistic landmarker dari android/assets/holistic_landmarker.task
///  - Inference lokal pakai tflite_flutter
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  CameraController? _camera;
  Interpreter? _interpreter;
  LandmarkExtractor? _extractor;
  final FrameBuffer _buffer = FrameBuffer(windowSize: 60, featureSize: 300);

  Map<String, int> _labelIndex = const {
    'bukan_saman': 0,
    'tari_saman': 1,
  };

  final ValueNotifier<double> accuracy = ValueNotifier<double>(0);
  final ValueNotifier<int> frameCount = ValueNotifier<int>(0);
  final ValueNotifier<String?> status = ValueNotifier<String?>(null);

  bool _initializing = false;
  bool _ready = false;
  bool _busy = false;
  String? _error;

  bool get ready => _ready;
  String? get error => _error;
  int get numClasses => _labelIndex.length;

  Widget? buildPreview() {
    final c = _camera;
    if (c == null || !c.value.isInitialized) return null;
    return CameraPreview(c);
  }

  Future<void> initialize() async {
    if (_initializing || _ready) return;
    _initializing = true;
    try {
      // 1. Izin kamera
      final perm = await Permission.camera.request();
      if (!perm.isGranted) {
        _error = 'Izin kamera ditolak.';
        status.value = _error;
        return;
      }

      // 2. Kamera
      final cams = await availableCameras();
      if (cams.isEmpty) {
        _error = 'Kamera tidak tersedia.';
        status.value = _error;
        return;
      }
      final cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await ctrl.initialize();
      _camera = ctrl;

      // 3. Label map (opsional)
      try {
        final raw = await rootBundle.loadString('assets/models/label_map.json');
        final map = jsonDecode(raw);
        if (map is Map) {
          _labelIndex = map.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          );
        }
      } catch (_) {
        // pakai default
      }

      // 4. TFLite interpreter
      try {
        _interpreter = await Interpreter.fromAsset(
          'assets/models/dance_detector.tflite',
        );
      } catch (e) {
        _error = 'Model TFLite gagal dimuat: $e';
        status.value = _error;
        return;
      }

      // 5. MediaPipe Holistic native extractor
      _extractor = MediaPipeHolisticExtractor();
      try {
        await _extractor!.initialize(modelPath: 'holistic_landmarker.task');
      } catch (e) {
        _error = 'Holistic extractor gagal init: $e';
        status.value = _error;
        return;
      }

      // 6. Mulai stream kamera
      await _camera!.startImageStream(_onFrame);
      _ready = true;
      status.value = 'Kamera & model siap.';
    } catch (e) {
      _error = 'Inisialisasi gagal: $e';
      status.value = _error;
    } finally {
      _initializing = false;
    }
  }

  void _onFrame(CameraImage image) {
    if (!_ready || _busy) return;
    _extractor?.extract(image).then((lm) {
      if (lm == null) return;
      try {
        _buffer.push(lm);
      } catch (_) {
        return;
      }
      frameCount.value = _buffer.length;
      if (_buffer.isFull) {
        _runInference();
      }
    }).catchError((Object e) {
      debugPrint('Extract error: $e');
    });
  }

  Future<void> _runInference() async {
    final interp = _interpreter;
    if (interp == null) return;
    _busy = true;
    try {
      final input = _buffer.asTensor();
      final n = numClasses;
      final output = List.generate(1, (_) => List<double>.filled(n, 0));
      interp.run(input, output);

      final samanIdx = _labelIndex['tari_saman'] ?? 1;
      final prob = output[0][samanIdx].clamp(0.0, 1.0);
      accuracy.value = (prob * 100).clamp(0, 100);
    } catch (e) {
      debugPrint('Inference error: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> dispose() async {
    await _camera?.stopImageStream().catchError((_) {});
    await _camera?.dispose();
    _interpreter?.close();
    await _extractor?.dispose();
    accuracy.dispose();
    frameCount.dispose();
    status.dispose();
  }
}
