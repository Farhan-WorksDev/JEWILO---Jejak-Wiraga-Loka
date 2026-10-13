import 'dart:async';
import 'package:flutter/material.dart';
import '../../ai/ai_service.dart';
import '../data/saman_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum _Phase { ready, move, rest, done }

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
  static const int _readySec = 3;
  static const int _miniTargetSec = 120;

  late final Variation v = samanVariations[widget.variationIndex];
  late final List<Move> moves = v.moves;

  Timer? _timer;
  _Phase phase = _Phase.ready;
  int idx = 0;
  double left = _readySec.toDouble();
  double total = 0;
  bool paused = false;
  bool _wasBackgrounded = false;

  // Track akurasi per gerakan
  final List<double> _accSum = [];
  final List<int> _accCount = [];
  double _currentAccSum = 0;
  int _currentAccCount = 0;

  Move get cur => moves[idx];
  bool get isLast => idx == moves.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AiService.instance.accuracy.addListener(_onAccuracy);
    _resetAccTracking();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _resetAccTracking() {
    _accSum.clear();
    _accCount.clear();
    for (var i = 0; i < moves.length; i++) {
      _accSum.add(0);
      _accCount.add(0);
    }
    _currentAccSum = 0;
    _currentAccCount = 0;
  }

  @override
  void dispose() {
    AiService.instance.accuracy.removeListener(_onAccuracy);
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onAccuracy() {
    final a = AiService.instance.accuracy.value;
    if (a > 0 && phase == _Phase.move) {
      _currentAccSum += a;
      _currentAccCount++;
      if (_currentAccCount % 5 == 0) {
        setState(() {
          _accSum[idx] = _currentAccSum;
          _accCount[idx] = _currentAccCount;
        });
      }
    }
  }

  double _avgAcc(int i) {
    if (i >= _accCount.length || _accCount[i] == 0) return 0;
    return _accSum[i] / _accCount[i];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && phase != _Phase.done) {
      _wasBackgrounded = true;
    }
    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      if (!mounted) return;
      _restart();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Latihan terhenti, otomatis diulang dari awal.')));
    }
  }

  void _restart() => setState(() {
        phase = _Phase.ready;
        idx = 0;
        left = _readySec.toDouble();
        total = 0;
        paused = false;
        _resetAccTracking();
      });

  void _tick() {
    if (paused || phase == _Phase.done || !mounted) return;
    setState(() {
      left -= .1;
      if (phase != _Phase.ready) total += .1;
      if (left <= 0.001) _advance();
    });
  }

  void _advance() {
    switch (phase) {
      case _Phase.ready:
        phase = _Phase.move;
        idx = 0;
        left = moves[0].durationSec;
        _currentAccSum = 0;
        _currentAccCount = 0;
        break;
      case _Phase.move:
        if (isLast) {
          if (widget.mini && total < _miniTargetSec) {
            idx = 0;
            left = moves[0].durationSec;
            _currentAccSum = 0;
            _currentAccCount = 0;
          } else {
            _finish();
          }
        } else if (cur.pauseAfterSec > 0) {
          phase = _Phase.rest;
          left = cur.pauseAfterSec;
        } else {
          idx++;
          left = cur.durationSec;
          _currentAccSum = 0;
          _currentAccCount = 0;
        }
        break;
      case _Phase.rest:
        phase = _Phase.move;
        idx++;
        left = cur.durationSec;
        _currentAccSum = 0;
        _currentAccCount = 0;
        break;
      case _Phase.done:
        break;
    }
  }

  Future<void> _finish() async {
    phase = _Phase.done;
    _timer?.cancel();
    await AppState.instance.recordSession(
      seconds: total.round(),
      variationIndex: widget.mini ? null : widget.variationIndex,
    );
    if (!mounted) return;
    final s = AppState.instance;
    final overall = _overallAcc();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            widget.mini
                ? 'Pemanasan selesai! 🔥'
                : 'Variasi ${v.level.label} selesai! 🎉',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18, color: C.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.mini
                ? 'Streak kamu terjaga: ${s.currentStreak} hari.'
                : 'Kamu menyelesaikan rangkaian dari awal sampai akhir.'),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.analytics_outlined,
                  size: 18, color: C.purple),
              const SizedBox(width: 6),
              Text('Akurasi rata-rata: ${overall.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            Text(
                widget.mini
                    ? '+10 XP'
                    : '+${v.level.xp} XP • Bar proses: ${s.completed.length}/3',
                style: const TextStyle(color: C.muted, fontSize: 12.5)),
          ],
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Lanjut')),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  double _overallAcc() {
    double sum = 0;
    int count = 0;
    for (var i = 0; i < moves.length; i++) {
      final avg = _avgAcc(i);
      if (avg > 0) {
        sum += avg;
        count++;
      }
    }
    return count == 0 ? 0 : sum / count;
  }

  Future<void> _confirmStop() async {
    setState(() => paused = true);
    final stop = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Berhenti sekarang?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(widget.mini
            ? 'Pemanasan belum selesai, streak belum tercatat.'
            : 'Latihan akan di-RESET dari gerakan pertama.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Lanjut Latihan')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Berhenti & Reset')),
        ],
      ),
    );
    if (!mounted) return;
    if (stop == true) {
      Navigator.pop(context, false);
    } else {
      setState(() => paused = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: phase == _Phase.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmStop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [
          // Camera preview
          AiService.instance.buildPreview() ??
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [C.darkBg, C.darkBgDeep],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                ),
                child: const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.videocam_outlined,
                        color: Colors.white24, size: 64),
                    SizedBox(height: 10),
                    Text('Kamera sedang disiapkan...',
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ]),
                ),
              ),

          // Top bar
          SafeArea(
            child: Column(children: [
              _topBar(),
              const Spacer(),

              // Instruction bubble (di tengah bawah)
              if (phase == _Phase.move && cur.inserted == false)
                _instructionBubble(),

              const SizedBox(height: 12),
            ]),
          ),

          // Bottom panel (bar + controls)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _progressPanel(),
                  const SizedBox(height: 12),
                  _controls(),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconButton.filled(
            style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: .5)),
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
                          fontSize: 14)),
                  Text(
                      widget.mini
                          ? 'Pemanasan'
                          : 'Variasi ${widget.variationIndex + 1} dari 3',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: C.green.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${AppState.instance.fps} FPS',
                style: const TextStyle(
                    color: C.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
      );

  Widget _instructionBubble() {
    final acc = _avgAcc(idx);
    final color = _colorFromAcc(acc);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(cur.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Text('${acc.toStringAsFixed(0)}%',
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _progressPanel() {
    if (widget.mini) {
      return _miniPanel();
    }

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
          // Info baris atas
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _colorFromAcc(_avgAcc(idx)).withValues(alpha: .2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('LANGKAH ${(idx + 1).toString().padLeft(2, '0')}',
                  style: TextStyle(
                      color: _colorFromAcc(_avgAcc(idx)),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5)),
            ),
            const SizedBox(width: 8),
            Text(cur.stage,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5)),
            const Spacer(),
            Text('${left.clamp(0, 99).toStringAsFixed(1)}s',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),

          // Bar per gerakan (visual utama)
          Row(
            children: [
              for (var i = 0; i < moves.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: i == moves.length - 1 ? 0 : 4),
                    child: _moveBar(i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Legend baris bawah
          Row(children: [
            _legendDot(C.green, 'Bagus'),
            const SizedBox(width: 10),
            _legendDot(C.orange, 'Sedang'),
            const SizedBox(width: 10),
            _legendDot(C.red, 'Kurang'),
          ]),
        ],
      ),
    );
  }

  Widget _moveBar(int i) {
    final isCurrent = phase != _Phase.ready && i == idx;
    final isPending = phase == _Phase.ready || i > idx;

    final acc = _avgAcc(i);
    final color = isPending
        ? Colors.white24
        : isCurrent
            ? _colorFromAcc(acc)
            : _colorFromAcc(acc);

    return Column(children: [
      // Bar utama
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
                      spreadRadius: 1),
                ]
              : null,
        ),
      ),
      const SizedBox(height: 4),
      // Label angka di bawah bar
      Text(
        isPending ? '—' : '${acc.toStringAsFixed(0)}%',
        style: TextStyle(
          color: isPending ? Colors.white38 : Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ]);
  }

  Widget _miniPanel() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.timer_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                  'Sisa ${fmtDur((_miniTargetSec - total).clamp(0, 999))}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text('${cur.name.split(' ').first}...',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (total / _miniTargetSec).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(C.orange),
              ),
            ),
          ],
        ),
      );

  Widget _legendDot(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      );

  Color _colorFromAcc(double acc) {
    if (acc >= 80) return C.green;
    if (acc >= 60) return C.orange;
    if (acc > 0) return C.red;
    return Colors.white38;
  }

  Widget _controls() => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: C.purple.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(
            tooltip: 'Ulang dari awal',
            onPressed: _restart,
            icon: const Icon(Icons.replay, color: Colors.white),
          ),
          FloatingActionButton(
            backgroundColor: C.orange,
            elevation: 0,
            onPressed: () => setState(() => paused = !paused),
            child: Icon(paused ? Icons.play_arrow : Icons.pause,
                color: Colors.white),
          ),
          IconButton(
            tooltip: 'Berhenti',
            style: IconButton.styleFrom(backgroundColor: C.red),
            onPressed: _confirmStop,
            icon: const Icon(Icons.stop, color: Colors.white),
          ),
        ]),
      );
}
