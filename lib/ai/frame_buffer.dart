import 'dart:collection';

/// Sliding window buffer 60 frame × 300 fitur (float64).
///
/// Referensi pipeline Python:
///   - windowSize = 60 (60 frame terakhir)
///   - featureSize = 300 (33 pose × 4 + 21 tangan × 4 + 21 tangan × 4)
class FrameBuffer {
  final int windowSize;
  final int featureSize;
  final Queue<List<double>> _frames = Queue();

  FrameBuffer({required this.windowSize, required this.featureSize});

  int get length => _frames.length;
  bool get isFull => _frames.length >= windowSize;

  void push(List<double> frame) {
    if (frame.length != featureSize) {
      throw ArgumentError('Frame size ${frame.length} != $featureSize');
    }
    _frames.addLast(frame);
    while (_frames.length > windowSize) {
      _frames.removeFirst();
    }
  }

  void clear() => _frames.clear();

  /// Return tensor 3D [1, windowSize, featureSize] untuk TFLite.
  List<List<List<double>>> asTensor() {
    if (!isFull) {
      throw StateError('Buffer belum penuh ($length/$windowSize)');
    }
    return [
      List<List<double>>.from(
        _frames.map((f) => List<double>.from(f)),
      )
    ];
  }
}
