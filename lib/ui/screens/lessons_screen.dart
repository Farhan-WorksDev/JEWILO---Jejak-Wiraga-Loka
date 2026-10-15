import 'package:flutter/material.dart';
import '../data/saman_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell_animation.dart';
import 'saman_detail_screen.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ListView(padding: EdgeInsets.zero, children: [
        GradientHeader(
          title: 'Latihan',
          subtitle: '${s.completed.length} dari 3 variasi selesai',
        ),
        SlideUpFade(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(children: [
              for (var i = 0; i < samanVariations.length; i++) ...[
                _variationCard(context, s, i),
                const SizedBox(height: 12),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _variationCard(BuildContext context, AppState s, int i) {
    final v = samanVariations[i];
    final done = s.completed.contains(i);
    final unlocked = s.isUnlocked(i);
    final accent = done ? C.green : unlocked ? C.purple : C.muted;

    return GestureDetector(
      onTap: unlocked
          ? () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SamanDetailScreen(initial: i)))
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : C.purpleSoft.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: unlocked ? C.line : Colors.transparent, width: 1),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                      color: C.purple.withValues(alpha: .06),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                      done
                          ? Icons.check_circle
                          : unlocked
                              ? Icons.play_circle_fill
                              : Icons.lock,
                      color: accent,
                      size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Variasi ${v.level.label}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                            '${v.moves.length} gerakan • ${fmtDur(v.totalSec)}${v.insertedCount > 0 ? ' • ${v.insertedCount} selipan' : ''}',
                            style: const TextStyle(
                                color: C.muted, fontSize: 12)),
                      ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: C.orangeSoft,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('+${v.level.xp}',
                      style: const TextStyle(
                          color: C.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 12),
              Text(v.focus,
                  style: const TextStyle(
                      color: C.muted, fontSize: 12.5, height: 1.4)),
            ]),
      ),
    );
  }
}