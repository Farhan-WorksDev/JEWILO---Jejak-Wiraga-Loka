import 'package:flutter/material.dart';
import '../data/saman_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'saman_detail_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ListView(padding: EdgeInsets.zero, children: [
        GradientHeader(
          title: 'Progress',
          subtitle: 'Semangat latihan Tari Saman!',
          bottom: _tabs(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: [_streak(s), _waktu(s), _status(context, s)][tab],
        ),
      ]),
    );
  }

  Widget _tabs() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.black26, borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          for (final e in ['Streak', 'Waktu', 'Status'].asMap().entries)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => tab = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tab == e.key ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(e.value,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: tab == e.key ? C.purple : Colors.white70)),
                ),
              ),
            ),
        ]),
      );

  // ============ TAB STREAK ============
  Widget _streak(AppState s) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    const names = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];

    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [C.orange, C.fireDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: C.orange.withValues(alpha: .18),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .15),
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withValues(alpha: .25),
                    blurRadius: 24,
                    spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.local_fire_department,
                color: Colors.white, size: 44),
          ),
          Text('${s.currentStreak} HARI',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900)),
          Text(
              s.currentStreak == 0
                  ? 'Mulai hari ini. Cukup 2 menit untuk menyalakan api!'
                  : 'Keren! Jangan sampai terlewat dua hari berturut-turut.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < 7; i++)
              Builder(builder: (_) {
                final d = monday.add(Duration(days: i));
                final done = (s.secondsByDay[dayKey(d)] ?? 0) > 0;
                final isToday = dayKey(d) == dayKey(now);
                return Column(children: [
                  Text(names[i],
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .8),
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? C.gold : Colors.white24,
                      border: isToday
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Icon(done ? Icons.check : Icons.remove,
                        color: Colors.white, size: 16),
                  ),
                ]);
              }),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _mini('Level ${s.level}', '${s.xp} XP',
                Icons.emoji_events, C.orange, C.orangeSoft)),
        const SizedBox(width: 12),
        Expanded(
            child: _mini('Streak Terbaik', '${s.longest} hari',
                Icons.military_tech, C.green, C.greenSoft)),
      ]),
      const SectionTitle('Jalur Gamifikasi'),
      _paths(s),
    ]);
  }

  Widget _mini(String t, String v, IconData i, Color c, Color bg) => CardBox(
        color: bg,
        border: c.withValues(alpha: .18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i, color: c),
          const SizedBox(height: 8),
          Text(v,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 20)),
          Text(t, style: const TextStyle(color: C.muted, fontSize: 12.5)),
        ]),
      );

  Widget _paths(AppState s) {
    final menit = s.totalSeconds ~/ 60;
    final items = [
      ('Jalur Gerak', Icons.accessibility_new,
          '${s.completed.length}/3 variasi', s.progress, C.purple),
      ('Jalur Ritme', Icons.music_note, '$menit/30 mnt',
          (menit / 30).clamp(0.0, 1.0), C.orange),
      ('Jalur Konsisten', Icons.local_fire_department,
          '${s.currentStreak}/7 hari',
          (s.currentStreak / 7).clamp(0.0, 1.0), C.red),
      ('Jalur Level', Icons.military_tech, '${s.xp % 100}/100 XP',
          ((s.xp % 100) / 100).clamp(0.0, 1.0), C.green),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        for (final i in items)
          CardBox(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(i.$2, color: i.$5, size: 22),
              const Spacer(),
              Text(i.$1,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13)),
              Text(i.$3,
                  style: const TextStyle(color: C.muted, fontSize: 11.5)),
              const SizedBox(height: 6),
              Bar(i.$4, color: i.$5, height: 5),
            ]),
          ),
      ],
    );
  }

  // ============ TAB WAKTU ============
  Widget _waktu(AppState s) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final secs = [
      for (var i = 0; i < 7; i++)
        s.secondsByDay[dayKey(monday.add(Duration(days: i)))] ?? 0
    ];
    final weekTotal = secs.fold(0, (a, b) => a + b);
    final maxSec = secs.fold<int>(300, (a, b) => b > a ? b : a);

    return Column(children: [
      CardBox(
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Waktu Minggu Ini',
                  style: TextStyle(color: C.muted, fontSize: 12.5)),
              Text(fmtDur(weekTotal),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: C.purple)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Seluruhnya',
                style: TextStyle(color: C.muted, fontSize: 12.5)),
            Text(fmtDur(s.totalSeconds),
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Distribusi Mingguan',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child:
                      Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(secs[i] == 0 ? '' : fmtDur(secs[i]),
                        style: const TextStyle(
                            fontSize: 9.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      height: 6 + 100 * (secs[i] / maxSec),
                      decoration: BoxDecoration(
                        color: monday.add(Duration(days: i)).day == now.day
                            ? C.orange
                            : C.purple.withValues(
                                alpha: secs[i] == 0 ? .15 : .85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(names[i],
                        style: const TextStyle(fontSize: 11, color: C.muted)),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    ]);
  }

  // ============ TAB STATUS ============
  Widget _status(BuildContext context, AppState s) => Column(children: [
        CardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                  child: Text('Tari Saman (Aceh)',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18))),
              Pill(s.allDone ? 'Tuntas' : 'Sedang dipelajari',
                  fg: C.orange, bg: C.orangeSoft),
            ]),
            const SizedBox(height: 4),
            Text('${s.completed.length} dari 3 variasi selesai',
                style: const TextStyle(color: C.muted, fontSize: 12.5)),
            const SizedBox(height: 10),
            Bar(s.progress),
          ]),
        ),
        const SectionTitle('Rincian Variasi'),
        for (var i = 0; i < 3; i++) ...[
          _variationRow(context, s, i),
          const SizedBox(height: 10),
        ],
        const SectionTitle('Lencana'),
        s.badges.isEmpty
            ? CardBox(
                child: Row(children: [
                  const Icon(Icons.workspace_premium_outlined,
                      color: C.muted, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Text(
                          'Belum ada lencana. Selesaikan latihan pertamamu!',
                          style: TextStyle(color: C.muted, fontSize: 13))),
                ]),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in badgeNames.entries)
                    _badgeTile(e.key, e.value, s.badges.contains(e.key)),
                ],
              ),
      ]);

  Widget _badgeTile(String key, String name, bool unlocked) => Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: unlocked ? C.orangeSoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: unlocked ? C.orange : C.line),
        ),
        child: Column(children: [
          Icon(
              unlocked
                  ? Icons.workspace_premium
                  : Icons.lock_outline,
              color: unlocked ? C.orange : C.muted,
              size: 26),
          const SizedBox(height: 6),
          Text(name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? C.ink : C.muted)),
        ]),
      );

  Widget _variationRow(BuildContext context, AppState s, int i) {
    final done = s.completed.contains(i);
    final unlocked = s.isUnlocked(i);
    final v = samanVariations[i];
    final label = done ? 'LULUS' : unlocked ? 'SIAP' : 'TERKUNCI';
    final color = done ? C.green : unlocked ? C.orange : C.muted;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: unlocked
          ? () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SamanDetailScreen(initial: i)))
          : null,
      child: CardBox(
        color: unlocked ? Colors.white : C.purpleSoft.withValues(alpha: .5),
        child: Row(children: [
          Icon(
              done
                  ? Icons.check_circle
                  : unlocked
                      ? Icons.hourglass_bottom
                      : Icons.lock,
              color: color),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w800)),
              Text('Variasi ${v.level.label}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              Text('${v.moves.length} gerakan • ${fmtDur(v.totalSec)}',
                  style: const TextStyle(color: C.muted, fontSize: 12)),
            ]),
          ),
          if (unlocked)
            const Icon(Icons.arrow_forward_ios, size: 14, color: C.muted),
        ]),
      ),
    );
  }
}
