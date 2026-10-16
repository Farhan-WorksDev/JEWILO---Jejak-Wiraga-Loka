import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../state/app_state.dart';

/// Service TTS untuk TalkBack.
///
/// Semua operasi TTS dibuat NON-BLOCKING supaya tap tombol di UI
/// tetap responsif walau TTS sedang bicara.
class TtsService extends ChangeNotifier {
  TtsService._();
  static final TtsService instance = TtsService._();

  FlutterTts? _tts;
  bool _ready = false;
  bool _speaking = false;
  String? _lastText;
  int _lastTextMs = 0;
  bool _noIndonesianVoice = false;

  static const int _debounceMs = 1800;

  bool get ready => _ready;
  bool get enabled => AppState.instance.talkBack;
  bool get noIndonesianVoice => _noIndonesianVoice;

  Future<void> init() async {
    if (_ready) return;
    try {
      final t = FlutterTts();

      // Cek apakah voice Indonesian tersedia
      bool hasIndonesian = false;
      try {
        final langs = await t.getLanguages;
        if (langs is List) {
          for (final l in langs) {
            final s = l.toString().toLowerCase();
            if (s.contains('id-id') ||
                s == 'id' ||
                s.contains('indonesia')) {
              hasIndonesian = true;
              break;
            }
          }
        }
      } catch (_) {}

      if (hasIndonesian) {
        try {
          await t.setLanguage('id-ID');
        } catch (_) {
          try {
            await t.setLanguage('id');
          } catch (_) {
            _noIndonesianVoice = true;
          }
        }
      } else {
        _noIndonesianVoice = true;
      }

      await t.setPitch(1.0);
      await t.setSpeechRate(AppState.instance.talkBackSpeed);
      await t.setVolume(AppState.instance.talkBackVolume);

      t.setStartHandler(() => _speaking = true);
      t.setCompletionHandler(() => _speaking = false);
      t.setCancelHandler(() => _speaking = false);
      t.setErrorHandler((msg) {
        _speaking = false;
        debugPrint('TTS error: $msg');
      });

      _tts = t;
      _ready = true;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS init gagal: $e');
    }
  }

  /// Interrupt — langsung bicara, ganti yang sedang diucapkan.
  /// **Non-blocking**: return segera, bicara di background.
  void speakNow(String text, {bool force = false}) {
    if (!enabled || !_ready || text.trim().isEmpty) return;
    if (!force && _isDuplicate(text)) return;
    _remember(text);
    unawaited(_speakInternal(text, interrupt: true));
  }

  /// Antri — skip kalau sedang bicara.
  /// **Non-blocking**: return segera.
  void speak(String text, {bool force = false}) {
    if (!enabled || !_ready || text.trim().isEmpty) return;
    if (_speaking) return;
    if (!force && _isDuplicate(text)) return;
    _remember(text);
    unawaited(_speakInternal(text, interrupt: false));
  }

  Future<void> _speakInternal(String text, {required bool interrupt}) async {
    try {
      if (interrupt) {
        // Timeout 500ms — jangan sampai hang
        await _tts?.stop().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {},
        );
      }
      final s = AppState.instance;
      await _tts?.setSpeechRate(s.talkBackSpeed);
      await _tts?.setVolume(s.talkBackVolume);
      await _tts?.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {},
      );
    } catch (_) {}
    _speaking = false;
  }

  bool _isDuplicate(String t) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastText == t && now - _lastTextMs < _debounceMs) return true;
    return false;
  }

  void _remember(String t) {
    _lastText = t;
    _lastTextMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// Force-reset kalau service stuck (misalnya setelah hot reload).
  void reset() {
    _speaking = false;
    _lastText = null;
    _lastTextMs = 0;
    try {
      _tts?.stop();
    } catch (_) {}
  }
}