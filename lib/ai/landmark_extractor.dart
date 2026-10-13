import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// Kontrak ekstraksi landmark 300 fitur dari 1 frame kamera.
///
/// Format referensi pipeline Python:
///   - Pose: 33 landmark × (x, y, z, visibility) = 132
///   - Tangan kiri: 21 × (x, y, z, presence) = 84
///   - Tangan kanan: 21 × (x, y, z, presence) = 84
///   → total 300 fitur
abstract class LandmarkExtractor {
  Future<void> initialize({required String modelPath});
  Future<List<double>?> extract(CameraImage image);
  Future<void> dispose();
}

/// Implementasi yang memanggil MethodChannel native
/// `com.belajarbareng/mediapipe_holistic` (Android Kotlin / iOS Swift).
class MediaPipeHolisticExtractor implements LandmarkExtractor {
  static const _channel = MethodChannel('com.belajarbareng/mediapipe_holistic');

  bool _initialized = false;
  bool _busy = false;

  @override
  Future<void> initialize({required String modelPath}) async {
    if (_initialized) return;
    try {
      await _channel.invokeMethod<bool>('initialize', {'modelPath': modelPath});
      _initialized = true;
    } on PlatformException catch (e) {
      throw LandmarkExtractionException('Gagal inisialisasi: ${e.message}');
    } on MissingPluginException {
      throw const LandmarkExtractionException(
        'Plugin MediaPipe belum terpasang. Jalankan flutter clean lalu rebuild.',
      );
    }
  }

  @override
  Future<List<double>?> extract(CameraImage image) async {
    if (!_initialized || _busy) return null;
    _busy = true;
    try {
      final args = _cameraImageToArgs(image);
      final result = await _channel.invokeMethod<List<dynamic>>('extract', args);
      if (result == null || result.isEmpty) return null;
      if (result.length != 300) {
        throw LandmarkExtractionException(
          'Native mengembalikan ${result.length} fitur, expected 300',
        );
      }
      return result.cast<double>();
    } on PlatformException catch (e) {
      throw LandmarkExtractionException('Ekstraksi gagal: ${e.message}');
    } finally {
      _busy = false;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod<void>('dispose');
    } on PlatformException {
      // Abaikan
    }
    _initialized = false;
  }

  Map<String, dynamic> _cameraImageToArgs(CameraImage image) {
    final y = image.planes[0];
    final u = image.planes[1];
    final v = image.planes[2];
    return {
      'width': image.width,
      'height': image.height,
      'yPlane': Uint8List.fromList(y.bytes),
      'uPlane': Uint8List.fromList(u.bytes),
      'vPlane': Uint8List.fromList(v.bytes),
      'yRowStride': y.bytesPerRow,
      'uvRowStride': u.bytesPerRow,
      'uvPixelStride': u.bytesPerPixel ?? 1,
      'rotation': 0,
    };
  }
}

class LandmarkExtractionException implements Exception {
  final String message;
  const LandmarkExtractionException(this.message);
  @override
  String toString() => 'LandmarkExtractionException: $message';
}
