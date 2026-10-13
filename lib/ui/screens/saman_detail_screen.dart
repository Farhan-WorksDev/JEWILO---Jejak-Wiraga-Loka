import 'package:flutter/material.dart';
import '../data/saman_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'practice_screen.dart';

class SamanDetailScreen extends StatefulWidget {
  final int initial;
  const SamanDetailScreen({super.key, this.initial = 0});
  @override
  State<SamanDetailScreen> createState() => _SamanDetailScreenState();
}

class _SamanDetailScreenState extends State<SamanDetailScreen> {
  late int sel = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final v = samanVariations[sel];
        final unlocked = s.isUnlocked(sel);
        return Scaffold(
          body: ListView(padding: EdgeInsets.zero, children: [
            _hero(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _selector(s),
                const SizedBox(height: 14),
                _infoBar(v),
                const SizedBox(height: 22),
                const Text('Rangkaian Gerakan',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Wajib berurutan dari awal sampai akhir',
                    style: TextStyle(color: C.muted, fontSize: 12)),
                const SizedBox(height: 12),
                for (var i = 0; i < v.moves.length; i++) ...[
                  _moveTile(i, v.moves[i]),
                  const SizedBox(height: 8),
                ],
              ]),
            ),
          ]),
          bottomSheet: _bottomBar(context, v, unlocked),
        );
      },
    );
  }

  Widget _hero(BuildContext context) => Container(
        height: 180,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [C.purpleDark, C.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('ACEH GAYO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: C.orange,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bolt, color: Colors.white, size: 12),
                    SizedBox(width: 2),
                    Text('DINAMIS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              const Text('Tari Saman',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );

  Widget _selector(AppState s) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: C.purpleSoft, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => sel = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: sel == i
                        ? [
                            BoxShadow(
                                color: C.purple.withValues(alpha: .1),
                                blurRadius: 4)
                          ]
                        : null,
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!s.isUnlocked(i))
                          const Icon(Icons.lock, size: 12, color: C.muted),
                        if (s.completed.contains(i))
                          const Icon(Icons.check_circle,
                              size: 13, color: C.green),
                        if (!s.isUnlocked(i) || s.completed.contains(i))
                          const SizedBox(width: 3),
                        Text(Level.values[i].label,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: sel == i ? C.purple : C.muted)),
                      ]),
                ),
              ),
            ),
        ]),
      );

  Widget _infoBar(Variation v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: C.bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          _infoItem(Icons.list_alt, '${v.moves.length} gerakan'),
          const SizedBox(width: 14),
          _infoItem(Icons.timer_outlined, fmtDur(v.totalSec)),
          if (v.insertedCount > 0) ...[
            const SizedBox(width: 14),
            _infoItem(Icons.add_circle_outline, '${v.insertedCount} selipan'),
          ],
        ]),
      );

  Widget _infoItem(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: C.purple),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: C.ink)),
        ],
      );

  Widget _moveTile(int i, Move m) {
    final accent = m.inserted ? C.orange : C.purple;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${i + 1}',
              style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.speed, size: 12, color: C.muted),
              const SizedBox(width: 3),
              Text(m.tempoLabel,
                  style: const TextStyle(color: C.muted, fontSize: 11.5)),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: C.muted)),
              const SizedBox(width: 8),
              Text(fmtSec(m.durationSec),
                  style: const TextStyle(color: C.muted, fontSize: 11.5)),
            ]),
            if (m.inserted) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: C.orange, borderRadius: BorderRadius.circular(8)),
                child: const Text('SELIPAN',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5)),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _bottomBar(BuildContext context, Variation v, bool unlocked) =>
      Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: C.line)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Variasi ${v.level.label}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text('~${fmtDur(v.totalSec)}',
                    style: const TextStyle(color: C.muted, fontSize: 12)),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: unlocked ? C.purple : C.muted,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            onPressed: unlocked
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PracticeScreen(variationIndex: sel)))
                : null,
            icon: Icon(unlocked ? (AppState.instance.completed.contains(sel) ? Icons.replay : Icons.camera_alt) : Icons.lock, size: 18),
            label: Text(unlocked ? (AppState.instance.completed.contains(sel) ? 'Ulangi Latihan' : 'Mulai Latihan') : 'Terkunci',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}
