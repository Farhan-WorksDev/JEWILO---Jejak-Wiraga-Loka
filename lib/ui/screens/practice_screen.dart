import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ai/ai_service.dart';
import '../../ai/pose_match.dart';
import '../data/saman_data.dart';
import '../services/music_service.dart';
import '../services/tts_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum _Phase { ready, move, rest, done }

class _Live {
  final PoseFrame? frame;
  final MatchResult? result;
  final PoseKeyframe? target;
  final double smooth;
  const _Live(this.frame, this.result, this.target, this.smooth);
}

Color _scoreColor(double s, bool visible) {
  if (!visible || s <= 0) return Colors.white38;
  if (s >= kGoodScore) return C.green;
  if (s >= kPassScore) return C.orange;
  return C.red;
}

class PracticeScreen extends StatefulWidget {
  final int variationIndex;
  final bool mini;

  const PracticeScreen({
    super.key,
    required this.variationIndex,
    this.mini = false,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with WidgetsBindingObserver {
  static const int _miniTargetSec = 120;
  static const int _readyHoldMs = 1500;
  static const int _skipAfterMs = 20000;

  late final Variation v = samanVariations[widget.variationIndex];
  late final List<Move> moves = v.moves;
  late final List<(int, PoseKeyframe)> _flat = [
    for (var i = 0; i < moves.length; i++)
      for (final k in keyframesFor(moves[i])) (i, k),
  ];

  _Phase phase = _Phase.ready;
  int idx = 0;
  int kfIdx = 0;
  late List<PoseKeyframe> kfs = keyframesFor(moves[0]);
  bool paused = false;
  bool showSkip = false;
  int total = 0;
  bool _wasBackgrounded = false;

  Timer? _clock;
  Timer? _restTimer;

  final ValueNotifier<_Live> _live = ValueNotifier<_Live>(
    const _Live(null, null, null, 0),
  );

  late List<double?> moveAcc = List<double?>.filled(moves.length, null);
  late List<bool> moveSkipped = List<bool>.filled(moves.length, false);
  final List<double> _kfScores = [];

  double _smooth = 0;
  double _holdSum = 0;
  int _holdCnt = 0;
  int? _holdStart;
  int? _visibleSince;
  int _kfStartMs = 0;

  int _miniStep = 0;
  double _miniAccSum = 0;
  int _miniAccCnt = 0;

  String? _lastSpokenHint;
  int _lastHintMs = 0;

  // ---- Countdown sebelum latihan ----
  int _countdownLeft = 0;
  bool _countdownRunning = false;

  Move get cur => moves[idx];
  bool get isLast => idx == moves.length - 1;
  int get _now => DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AiService.instance.pose.addListener(_onPose);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _clockTick());
    _startAi();
    MusicService.instance.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mq = MediaQuery.maybeOf(context);
      if (mq?.accessibleNavigation == true) return;
      TtsService.instance.speakNow(
        widget.mini
            ? 'Mode pemanasan dua menit. Berdiri di depan kamera, '
                'badan harus terlihat penuh.'
            : 'Halaman Latihan. Variasi ${v.level.label}. ${moves.length} gerakan. '
                'Berdiri di depan kamera, badan harus terlihat penuh.',
      );
    });
  }

  Future<void> _startAi() async {
    await AiService.instance.start();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AiService.instance.pose.removeListener(_onPose);
    _clock?.cancel();
    _restTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(TtsService.instance.stop());
    unawaited(MusicService.instance.stop());
    super.dispose();
    unawaited(AiService.instance.stop());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && phase != _Phase.done) {
      _wasBackgrounded = true;
      MusicService.instance.pause();
    }
    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      _recoverFromBackground();
    }
  }

  Future<void> _recoverFromBackground() async {
    await AiService.instance.stop();
    if (!mounted) return;
    _restart();
    await AiService.instance.start();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Latihan terhenti, otomatis diulang dari awal.'),
      ),
    );
  }

  PoseKeyframe _currentTarget() {
    if (widget.mini) {
      return phase == _Phase.ready
          ? _flat.first.$2
          : _flat[_miniStep % _flat.length].$2;
    }
    if (phase == _Phase.ready) return keyframesFor(moves[0]).first;
    return kfs[kfIdx.clamp(0, kfs.length - 1).toInt()];
  }

  void _onPose() {
    if (!mounted) return;
    final ai = AiService.instance;
    final f = ai.pose.value;
    final now = _now;
    final target = _currentTarget();
    final MatchResult? r = (f != null && now - f.timestampMs < 1000)
        ? matchPose(f, target, mirror: ai.mirror, frame: ai.uprightSize)
        : null;
    final visible = r != null && r.bodyVisible;

    if (!paused && phase != _Phase.done && !_countdownRunning) {
      switch (phase) {
        case _Phase.ready:
          if (visible) {
            _visibleSince ??= now;
            if (now - _visibleSince! >= _readyHoldMs) {
              _startCountdown();
            }
          } else {
            _visibleSince = null;
          }
          break;
        case _Phase.move:
          if (visible) {
            final sc = r.score;
            _smooth = _smooth == 0 ? sc : _smooth * 0.5 + sc * 0.5;
          } else {
            _smooth = _smooth < 1 ? 0 : _smooth * 0.6;
          }
          if (widget.mini) {
            if (visible) {
              _miniAccSum += r.score;
              _miniAccCnt++;
            }
          } else if (_smooth >= kPassScore) {
            _holdStart ??= now;
            _holdSum += _smooth;
            _holdCnt++;
            if (now - _holdStart! >= target.holdMs) _keyframeHit();
          } else {
            _holdStart = null;
            _holdSum = 0;
            _holdCnt = 0;
          }
          break;
        case _Phase.rest:
        case _Phase.done:
          break;
      }
    }

    if (phase == _Phase.move && !paused) {
      final hint = (r != null && r.bodyVisible) ? r.hint : null;
      if (hint != null &&
          hint != _lastSpokenHint &&
          now - _lastHintMs > 2500) {
        _lastSpokenHint = hint;
        _lastHintMs = now;
        TtsService.instance.speak(hint);
      }
    }

    if (mounted) _live.value = _Live(f, r, _currentTarget(), _smooth);
  }

  Future<void> _startCountdown() async {
    if (_countdownRunning) return;
    debugPrint('CD: start');
    _countdownRunning = true;
    setState(() => _countdownLeft = 5);
    TtsService.instance.speakNow('Bersiap. Lima.');

    for (var i = 4; i >= 1; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || phase != _Phase.ready) {
        _countdownRunning = false;
        return;
      }
      setState(() => _countdownLeft = i);
      if (i == 4) {
        TtsService.instance.speak('Empat.');
      } else if (i == 3) {
        TtsService.instance.speak('Tiga.');
      } else if (i == 2) {
        TtsService.instance.speak('Dua.');
      } else if (i == 1) {
        TtsService.instance.speak('Satu.');
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || phase != _Phase.ready) {
      _countdownRunning = false;
      return;
    }
    setState(() => _countdownLeft = 0);
    _countdownRunning = false;
    debugPrint('CD: finish, mulai latihan');
    _startMoves();
  }

  void _startMoves() {
    _visibleSince = null;
    _kfStartMs = _now;
    _smooth = 0;
    setState(() {
      phase = _Phase.move;
      idx = widget.mini ? _flat.first.$1 : 0;
      kfIdx = 0;
      kfs = keyframesFor(moves[idx]);
      _miniStep = 0;
    });
    if (widget.mini) {
      TtsService.instance.speakNow('Pemanasan dimulai. Ikuti gerakan.');
    } else {
      final target = _currentTarget();
      TtsService.instance.speakNow(
        'Mulai. Gerakan satu: ${moves[0].name}. Pose: ${target.label}.',
      );
    }
    MusicService.instance.play();
  }

  void _keyframeHit() {
    final score = _holdCnt == 0 ? _smooth : _holdSum / _holdCnt;
    _kfScores.add(score);
    HapticFeedback.lightImpact();
    _holdStart = null;
    _holdSum = 0;
    _holdCnt = 0;
    _smooth = 0;
    _kfStartMs = _now;
    if (kfIdx + 1 < kfs.length) {
      setState(() {
        kfIdx++;
        showSkip = false;
      });
      TtsService.instance.speak('Bagus. Lanjut pose berikutnya.');
    } else {
      final acc = _kfScores.reduce((a, b) => a + b) / _kfScores.length;
      _completeMove(acc);
    }
  }

  void _skip() => _completeMove(0, skipped: true);

  void _completeMove(double acc, {bool skipped = false}) {
    moveAcc[idx] = acc;
    moveSkipped[idx] = skipped;
    _kfScores.clear();
    _holdStart = null;
    _holdSum = 0;
    _holdCnt = 0;
    _smooth = 0;
    _lastSpokenHint = null;
    _lastHintMs = 0;

    if (!widget.mini) {
      if (isLast) {
        TtsService.instance.speakNow('Gerakan terakhir selesai.');
      } else {
        TtsService.instance.speakNow(
          'Gerakan ${idx + 1} selesai. Siap ke gerakan berikutnya.',
        );
      }
    }

    if (isLast) {
      _finish();
      return;
    }
    setState(() {
      phase = _Phase.rest;
      showSkip = false;
    });
    _restTimer?.cancel();
    _restTimer = Timer(const Duration(milliseconds: 900), _nextMove);
  }

  void _nextMove() {
    if (!mounted || phase == _Phase.done) return;
    _kfStartMs = _now;
    setState(() {
      idx++;
      kfIdx = 0;
      kfs = keyframesFor(moves[idx]);
      phase = _Phase.move;
    });
    final target = _currentTarget();
    TtsService.instance.speakNow(
      'Gerakan ${idx + 1}: ${moves[idx].name}. Pose: ${target.label}.',
    );
  }

  void _clockTick() {
    if (!mounted || paused || phase == _Phase.done) return;
    _onPose();
    if (phase == _Phase.ready) return;

    if (phase == _Phase.move || phase == _Phase.rest) total++;

    if (widget.mini) {
      if (phase == _Phase.move) {
        if (total % 2 == 0) {
          _miniStep++;
          idx = _flat[_miniStep % _flat.length].$1;
          _smooth = 0;
        }
        if (total >= _miniTargetSec) {
          _finish();
          return;
        }
        setState(() {});
      }
      return;
    }

    if (phase == _Phase.move &&
        !showSkip &&
        _now - _kfStartMs >= _skipAfterMs) {
      setState(() => showSkip = true);
    }
  }

  void _restart() {
    _restTimer?.cancel();
    _countdownRunning = false;
    _countdownLeft = 0;
    _kfScores.clear();
    _holdStart = null;
    _holdSum = 0;
    _holdCnt = 0;
    _visibleSince = null;
    _smooth = 0;
    _miniStep = 0;
    _miniAccSum = 0;
    _miniAccCnt = 0;
    _lastSpokenHint = null;
    _lastHintMs = 0;
    setState(() {
      phase = _Phase.ready;
      idx = 0;
      kfIdx = 0;
      kfs = keyframesFor(moves[0]);
      total = 0;
      paused = false;
      showSkip = false;
      moveAcc = List<double?>.filled(moves.length, null);
      moveSkipped = List<bool>.filled(moves.length, false);
    });
    TtsService.instance.speakNow('Diulang dari awal. Bersiap.');
    MusicService.instance.stop();
  }

  double _overallAcc() {
    if (widget.mini) {
      return _miniAccCnt == 0 ? 0 : _miniAccSum / _miniAccCnt;
    }
    final done = moveAcc.whereType<double>().toList();
    if (done.isEmpty) return 0;
    return done.reduce((a, b) => a + b) / done.length;
  }

  Future<void> _finish() async {
    if (phase == _Phase.done) return;
    setState(() => phase = _Phase.done);
    _clock?.cancel();
    _restTimer?.cancel();
    MusicService.instance.stop();

    final skipped = moveSkipped.any((e) => e);
    if (!skipped) {
      await AppState.instance.recordSession(
        seconds: math.max(total, 1),
        variationIndex: widget.mini ? null : widget.variationIndex,
      );
    }
    if (!mounted) return;
    final s = AppState.instance;
    final overall = _overallAcc();

    final accText = overall.toStringAsFixed(0);
    if (skipped) {
      TtsService.instance.speakNow(
        'Latihan dihentikan. Ada gerakan yang dilewati, jadi belum '
        'dihitung. Coba ulangi dari awal.',
      );
    } else {
      TtsService.instance.speakNow(
        widget.mini
            ? 'Pemanasan selesai. Akurasi rata-rata $accText persen. '
                'Streak kamu ${s.currentStreak} hari.'
            : 'Latihan selesai. Akurasi rata-rata $accText persen. '
                'Kerja bagus.',
      );
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          skipped
              ? 'Belum lulus 😅'
              : widget.mini
              ? 'Pemanasan selesai! 🔥'
              : 'Variasi ${v.level.label} selesai! 🎉',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: C.ink,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skipped
                  ? 'Ada gerakan yang dilewati, jadi variasi ini belum dihitung. Coba ulangi ya!'
                  : widget.mini
                  ? 'Streak kamu terjaga: ${s.currentStreak} hari.'
                  : 'Semua gerakan berhasil kamu ikuti dari awal sampai akhir.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 18, color: C.purple),
                const SizedBox(width: 6),
                Text(
                  'Akurasi rata-rata: ${overall.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (!skipped)
              Text(
                widget.mini
                    ? '+10 XP'
                    : '+${v.level.xp} XP • Bar proses: ${s.completed.length}/3',
                style: const TextStyle(color: C.muted, fontSize: 12.5),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, !skipped);
  }

  Future<void> _confirmStop() async {
    setState(() => paused = true);
    MusicService.instance.pause();
    final stop = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Berhenti sekarang?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          widget.mini
              ? 'Pemanasan belum selesai, streak belum tercatat.'
              : 'Latihan akan di-RESET dari gerakan pertama.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Lanjut Latihan'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Berhenti & Reset'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (stop == true) {
      TtsService.instance.speakNow('Latihan dihentikan.');
      MusicService.instance.stop();
      Navigator.pop(context, false);
    } else {
      setState(() => paused = false);
      MusicService.instance.resume();
    }
  }

  void _openMusicSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _MusicSettingsSheet(),
    );
  }

  void _printCalibration() {
    final ai = AiService.instance;
    final f = ai.pose.value;
    void snack(String m) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    if (f == null) {
      snack('Badan belum terdeteksi.');
      return;
    }
    final a = [
      for (final b in kBones)
        liveSegAngle(f, b[0], b[1], mirror: ai.mirror, frame: ai.uprightSize),
    ];
    if (a.any((e) => e == null)) {
      snack('Kedua tangan harus terlihat penuh.');
      return;
    }
    final tilt = liveTilt(f, mirror: ai.mirror, frame: ai.uprightSize);
    final code =
        "PoseKeyframe('NAMA', [${a.map((e) => e!.round()).join(', ')}], tilt: ${tilt?.round()})";
    debugPrint('KALIBRASI $code');
    snack('Pose tercetak di logcat (cari "KALIBRASI").');
  }

  @override
  Widget build(BuildContext context) {
    final ai = AiService.instance;
    return PopScope(
      canPop: phase == _Phase.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmStop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: ListenableBuilder(
          listenable: Listenable.merge([ai.readyNotifier, ai.status]),
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              _cameraLayer(),
              IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _SkeletonPainter(
                      live: _live,
                      mirror: ai.mirror,
                      frame: ai.uprightSize,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPress: _printCalibration,
                ),
              ),
              if (_countdownLeft > 0) _countdownOverlay(),
              SafeArea(child: Column(children: [_topBar(), const Spacer()])),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _progressPanel(),
                        const SizedBox(height: 12),
                        _controls(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countdownOverlay() => Positioned.fill(
        child: IgnorePointer(
          child: Container(
            color: Colors.black.withValues(alpha: .55),
            alignment: Alignment.center,
            child: Container(
              width: 180,
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: C.orange, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: C.orange.withValues(alpha: .7),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '$_countdownLeft',
                style: TextStyle(
                  color: C.orange,
                  fontSize: 110,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _cameraLayer() {
    final ai = AiService.instance;
    final c = ai.camera;
    if (ai.ready && c != null && c.value.isInitialized) {
      final ps = c.value.previewSize ?? const Size(720, 480);
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ps.height,
            height: ps.width,
            child: CameraPreview(c),
          ),
        ),
      );
    }
    final err = ai.error;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.darkBg, C.darkBgDeep],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                err == null ? Icons.videocam_outlined : Icons.videocam_off,
                color: Colors.white24,
                size: 64,
              ),
              const SizedBox(height: 10),
              Text(
                err ?? 'Kamera sedang disiapkan...',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              if (err != null) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _startAi,
                  child: const Text('Coba lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: .5),
          ),
          onPressed: _confirmStop,
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mini
                      ? 'Mode 2 Menit'
                      : 'Tari Saman • ${v.level.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  widget.mini
                      ? 'Pemanasan'
                      : 'Variasi ${widget.variationIndex + 1} dari 3',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: .5),
          ),
          tooltip: 'Pengaturan musik',
          onPressed: () => _openMusicSettings(context),
          icon: const Icon(Icons.music_note, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder<int>(
          valueListenable: AiService.instance.detectFps,
          builder: (_, fps, _) {
            final good = fps >= 8;
            final col = good ? C.success : C.orange;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: col.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$fps FPS',
                style: TextStyle(
                  color: col,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _progressPanel() {
    final target = _currentTarget();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: C.glowPurple.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.mini
                      ? 'PEMANASAN'
                      : 'LANGKAH ${(idx + 1).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: C.glowPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                cur.stage,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
              const Spacer(),
              if (!widget.mini && phase != _Phase.ready)
                Text(
                  'Pose ${kfIdx + 1}/${kfs.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (widget.mini)
                Text(
                  'Sisa ${fmtDur((_miniTargetSec - total).clamp(0, 999))}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cur.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            phase == _Phase.ready
                ? (_countdownLeft > 0
                    ? 'Bersiap dalam $_countdownLeft...'
                    : 'Ikuti kerangka putih di layar')
                : '▶ ${target.label}',
            style: const TextStyle(
              color: C.glowPurple,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (phase != _Phase.ready)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                cur.pose,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          const SizedBox(height: 10),
          _liveBar(),
          const SizedBox(height: 10),
          if (!widget.mini)
            Row(
              children: [
                for (var i = 0; i < moves.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == moves.length - 1 ? 0 : 4,
                      ),
                      child: _moveBar(i),
                    ),
                  ),
              ],
            ),
          if (!widget.mini) const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(C.green, 'Bagus'),
              const SizedBox(width: 10),
              _legendDot(C.orange, 'Cukup'),
              const SizedBox(width: 10),
              _legendDot(C.red, 'Kurang'),
              const Spacer(),
              const Text(
                'putih = target',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _liveBar() => ValueListenableBuilder<_Live>(
    valueListenable: _live,
    builder: (_, l, _) {
      final r = l.result;
      final visible = r != null && r.bodyVisible;
      final active = phase == _Phase.move;
      final s = (visible && active) ? l.smooth : 0.0;
      final color = _scoreColor(s, visible && active);

      String hint;
      Color hintColor = Colors.white70;
      if (phase == _Phase.rest) {
        hint = '✓ Bagus! Lanjut ke langkah berikutnya';
        hintColor = C.success;
      } else if (!visible) {
        hint = r?.hint ?? 'Badan belum terdeteksi, mundur sedikit';
        hintColor = C.orange;
      } else if (phase == _Phase.ready) {
        hint = _countdownLeft > 0
            ? 'Bersiap dalam $_countdownLeft...'
            : 'Terdeteksi ✓ Tahan sebentar, latihan segera dimulai';
        hintColor = C.success;
      } else if (widget.mini) {
        hint = r.hint ?? '✓ Pas!';
        hintColor = r.hint == null ? C.success : Colors.white70;
      } else if (s >= kGoodScore) {
        hint = '✓ Pas! Tahan sebentar';
        hintColor = C.success;
      } else if (s >= kPassScore) {
        hint = '✓ Hampir, tahan posisinya';
        hintColor = C.orange;
      } else {
        hint = r.hint ?? 'Ikuti pose putih di layar';
        hintColor = C.red;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 14,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Container(color: Colors.white12),
                      ),
                      FractionallySizedBox(
                        widthFactor: (s / 100).clamp(0.0, 1.0).toDouble(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment(kPassScore / 100 * 2 - 1, 0),
                        child: Container(width: 2, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 42,
                child: Text(
                  '${s.round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hintColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    },
  );

  Widget _moveBar(int i) {
    final done = moveAcc[i] != null;
    final isCurrent =
        phase != _Phase.ready && phase != _Phase.done && i == idx && !done;
    final acc = moveAcc[i] ?? 0;
    final color = done
        ? (moveSkipped[i] ? C.red : _scoreColor(acc, true))
        : isCurrent
        ? C.glowPurple
        : Colors.white24;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          done ? '${acc.toStringAsFixed(0)}%' : '—',
          style: TextStyle(
            color: done ? Colors.white : Colors.white38,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ],
  );

  Widget _controls() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: C.purple.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          tooltip: 'Ulang dari awal',
          onPressed: _restart,
          icon: const Icon(Icons.replay, color: Colors.white),
        ),
        if (showSkip && !widget.mini)
          TextButton.icon(
            onPressed: _skip,
            icon: const Icon(Icons.skip_next, color: Colors.white),
            label: const Text(
              'Lewati',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        FloatingActionButton(
          backgroundColor: C.orange,
          elevation: 0,
          onPressed: () {
            setState(() => paused = !paused);
            if (paused) {
              MusicService.instance.pause();
            } else {
              MusicService.instance.resume();
            }
          },
          child: Icon(
            paused ? Icons.play_arrow : Icons.pause,
            color: Colors.white,
          ),
        ),
        IconButton(
          tooltip: 'Berhenti',
          style: IconButton.styleFrom(backgroundColor: C.red),
          onPressed: _confirmStop,
          icon: const Icon(Icons.stop, color: Colors.white),
        ),
      ],
    ),
  );
}

// ===========================================================================
// Music Settings Sheet
// ===========================================================================
class _MusicSettingsSheet extends StatelessWidget {
  const _MusicSettingsSheet();

  static final Map<double, String> _rateOptions = {
    0.5: 'Sangat lambat (0.5x)',
    0.75: 'Lambat (0.75x)',
    1.0: 'Normal (1x)',
    1.25: 'Cepat (1.25x)',
    1.5: 'Sangat cepat (1.5x)',
    2.0: 'Ekstra cepat (2x)',
  };

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: C.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: C.purpleSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.music_note,
                          color: C.purple, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Musik Latihan',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: C.ink)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nyalakan musik',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5)),
                          SizedBox(height: 2),
                          Text('Lagu akan diputar selama latihan',
                              style: TextStyle(
                                  fontSize: 11.5, color: C.muted)),
                        ],
                      ),
                    ),
                    Switch(
                      value: s.musicOn,
                      activeThumbColor: Colors.white,
                      activeTrackColor: C.purple,
                      onChanged: (v) {
                        s.update(() => s.musicOn = v);
                        if (v) {
                          MusicService.instance.play();
                        } else {
                          MusicService.instance.pause();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Tempo musik',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 6),
                const Text(
                    'Pilih kecepatan lagu. Lambat untuk latihan pemula, cepat untuk mahir.',
                    style: TextStyle(
                        fontSize: 11.5, color: C.muted, height: 1.4)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: C.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.line),
                  ),
                  child: DropdownButton<double>(
                    value: s.musicRate,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: C.muted),
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: C.ink,
                        fontWeight: FontWeight.w600),
                    items: _rateOptions.entries
                        .map((e) => DropdownMenuItem<double>(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: s.musicOn
                        ? (v) {
                            if (v == null) return;
                            s.update(() => s.musicRate = v);
                            MusicService.instance.setRate(v);
                          }
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Volume musik',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: C.purple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(s.musicVolume * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .3),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: C.purple,
                    inactiveTrackColor: C.line,
                    thumbColor: C.purple,
                    overlayColor: C.purple.withValues(alpha: .12),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: s.musicVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: s.musicOn
                        ? (v) {
                            s.update(() => s.musicVolume = v);
                            MusicService.instance.setVolume(v);
                          }
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: C.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Painter
// ===========================================================================
class _SkeletonPainter extends CustomPainter {
  final ValueNotifier<_Live> live;
  final bool mirror;
  final Size frame;

  _SkeletonPainter({
    required this.live,
    required this.mirror,
    required this.frame,
  }) : super(repaint: live);

  @override
  bool shouldRepaint(covariant _SkeletonPainter old) =>
      old.mirror != mirror || old.frame != frame || old.live != live;

  @override
  void paint(Canvas canvas, Size size) {
    final l = live.value;
    if (l.target != null) _drawTarget(canvas, size, l.target!);
    if (l.frame != null) _drawLive(canvas, size, l.frame!, l.result);
  }

  void _drawTarget(Canvas canvas, Size size, PoseKeyframe t) {
    final unit = size.width * 0.26;
    final origin = Offset(size.width / 2, size.height * 0.30);
    final p = templatePoints(t).map((e) => origin + e * unit).toList();
    const bones = [
      [0, 1],
      [0, 2],
      [2, 4],
      [1, 3],
      [3, 5],
      [0, 6],
      [1, 7],
      [6, 7],
    ];
    final halo = Paint()
      ..color = C.glowPurple.withValues(alpha: .35)
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    for (final b in bones) {
      canvas.drawLine(p[b[0]], p[b[1]], halo);
    }
    for (final b in bones) {
      canvas.drawLine(p[b[0]], p[b[1]], line);
    }
    final joint = Paint()..color = Colors.white;
    for (final i in [0, 1, 2, 3, 4, 5]) {
      canvas.drawCircle(p[i], 6, joint);
    }
    canvas.drawCircle(
      p[8],
      unit * 0.3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = Colors.white.withValues(alpha: .8),
    );
  }

  Offset _map(PoseFrame f, int i, Size s) {
    final sc = math.max(s.width / frame.width, s.height / frame.height);
    final dw = frame.width * sc, dh = frame.height * sc;
    final ox = (s.width - dw) / 2, oy = (s.height - dh) / 2;
    final nx = mirror ? 1 - f.x(i) : f.x(i);
    return Offset(ox + nx * dw, oy + f.y(i) * dh);
  }

  void _drawLive(Canvas canvas, Size size, PoseFrame f, MatchResult? r) {
    const bones = [
      [Lm.lSh, Lm.rSh, -1],
      [Lm.lSh, Lm.lEl, 0],
      [Lm.lEl, Lm.lWr, 1],
      [Lm.rSh, Lm.rEl, 2],
      [Lm.rEl, Lm.rWr, 3],
      [Lm.lSh, Lm.lHip, -1],
      [Lm.rSh, Lm.rHip, -1],
      [Lm.lHip, Lm.rHip, -1],
    ];
    final colorOf = <int, Color>{};
    for (final b in bones) {
      if (!lmVisible(f, b[0]) || !lmVisible(f, b[1])) continue;
      var col = Colors.white70;
      if (b[2] >= 0 && r != null && r.segScore[b[2]] != null) {
        col = _scoreColor(r.segScore[b[2]]!, true);
        colorOf[b[1]] = col;
      }
      final a = _map(f, b[0], size), c = _map(f, b[1], size);
      canvas.drawLine(
        a,
        c,
        Paint()
          ..color = Colors.black.withValues(alpha: .35)
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        a,
        c,
        Paint()
          ..color = col
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final i in [
      Lm.lSh,
      Lm.rSh,
      Lm.lEl,
      Lm.rEl,
      Lm.lWr,
      Lm.rWr,
      Lm.lHip,
      Lm.rHip,
    ]) {
      if (!lmVisible(f, i)) continue;
      final pt = _map(f, i, size);
      canvas.drawCircle(pt, 7, Paint()..color = Colors.white);
      canvas.drawCircle(pt, 4.5, Paint()..color = colorOf[i] ?? Colors.white70);
    }
    if (lmVisible(f, Lm.nose) && lmVisible(f, Lm.lSh) && lmVisible(f, Lm.rSh)) {
      final shoulderPx =
          (_map(f, Lm.lSh, size) - _map(f, Lm.rSh, size)).distance;
      canvas.drawCircle(
        _map(f, Lm.nose, size),
        shoulderPx * 0.3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white70,
      );
    }

    if (r != null && r.bodyVisible && r.hint != null && r.worst >= 0) {
      Offset at;
      if (r.worst == 4) {
        at = (_map(f, Lm.lSh, size) + _map(f, Lm.rSh, size)) / 2;
      } else {
        at = _map(f, kBones[r.worst][1], size);
      }
      _drawLabel(canvas, size, at, r.hint!, C.orange);
    }
  }

  void _drawLabel(Canvas canvas, Size size, Offset at, String text, Color bg) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final w = tp.width + 20, h = tp.height + 12;
    var x = at.dx - w / 2;
    var y = at.dy - h - 14;
    x = math.min(math.max(x, 8.0), math.max(8.0, size.width - w - 8));
    y = math.min(math.max(y, 8.0), math.max(8.0, size.height - h - 8));
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, Paint()..color = bg.withValues(alpha: .92));
    tp.paint(canvas, Offset(x + 10, y + 6));
  }
}