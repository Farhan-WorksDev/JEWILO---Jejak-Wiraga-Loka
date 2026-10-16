import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../state/app_state.dart';

class MusicService extends ChangeNotifier {
  MusicService._();
  static final MusicService instance = MusicService._();

  AudioPlayer? _player;
  bool _ready = false;
  bool _playing = false;
  bool _sourceReady = false;

  static const String _assetPath = 'music/practice_bgm.mp3';

  bool get ready => _ready;
  bool get playing => _playing;

  Future<void> init() async {
    if (_ready) return;
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(AppState.instance.musicVolume);
      await p.setPlaybackRate(AppState.instance.musicRate);
      _player = p;
      _ready = true;
      debugPrint('MusicService: init OK');
      notifyListeners();
    } catch (e) {
      debugPrint('MusicService init gagal: $e');
    }
  }

  /// Play dari awal — pakai setSource + resume (paling reliable).
  Future<void> play() async {
    if (!_ready) await init();
    if (!_ready || !AppState.instance.musicOn) return;
    try {
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(AppState.instance.musicVolume);
      await _player!.setPlaybackRate(AppState.instance.musicRate);
      await _player!.setSource(AssetSource(_assetPath));
      _sourceReady = true;
      await _player!.resume();
      _playing = true;
      debugPrint('MusicService: playing');
      notifyListeners();
    } catch (e) {
      debugPrint('MusicService play error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player?.pause();
      _playing = false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (!_ready || !_sourceReady) {
      await play();
      return;
    }
    try {
      await _player!.resume();
      _playing = true;
      debugPrint('MusicService: resumed');
      notifyListeners();
    } catch (_) {
      await play();
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
      _playing = false;
      _sourceReady = false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setVolume(double v) async {
    try {
      await _player?.setVolume(v);
    } catch (_) {}
  }

  Future<void> setRate(double v) async {
    try {
      await _player?.setPlaybackRate(v);
    } catch (_) {}
  }
}