import 'package:flutter/material.dart';
import '../data/saman_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/shell_animation.dart';
import '../widgets/screen_announcer.dart';
import 'notifications_screen.dart';
import 'practice_screen.dart';
import 'saman_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int) goTab;
  const HomeScreen({super.key, required this.goTab});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ListView(
        padding: EdgeInsets.zero,
        children: [
          _header(context, s),
          SlideUpFade(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroCard(context, s),
                  const SizedBox(height: 14),
                  _quickActions(context, s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppState s) => Container(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 14, 20, 22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [C.purpleDark, C.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(
                radius: 22,
                backgroundColor: C.orange,
                child: Icon(Icons.self_improvement, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Hi, ${s.name}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      if (s.isOffline) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: C.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('OFFLINE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .5)),
                        ),
                      ],
                    ]),
                    Text(
                        s.practicedToday
                            ? 'Latihan hari ini sudah beres ✔'
                            : 'Yuk latihan hari ini',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: .7),
                            fontSize: 12.5)),
                  ]),
            ),
            if (!s.focusMode) _bellIcon(context),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _searchBar(context)),
            if (!s.focusMode) ...[
              const SizedBox(width: 10),
              _streakChip(s),
            ],
          ]),
        ]),
      );

  Widget _bellIcon(BuildContext context) => GestureDetector(
        onTap: () {
          announceAction('Membuka halaman notifikasi');
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        },
        child: Stack(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
                color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none,
                color: Colors.white, size: 22),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: C.orange, shape: BoxShape.circle),
            ),
          ),
        ]),
      );

  Widget _searchBar(BuildContext context) => GestureDetector(
        onTap: () {
          announceAction('Membuka halaman pencarian');
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SearchScreen()));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Row(children: const [
            Icon(Icons.search, color: C.muted, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('Cari tarian atau sanggar...',
                  style: TextStyle(color: C.muted, fontSize: 13)),
            ),
          ]),
        ),
      );

  Widget _streakChip(AppState s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.local_fire_department, color: C.orange, size: 18),
          const SizedBox(width: 4),
          Text('${s.currentStreak}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ]),
      );

  Widget _heroCard(BuildContext context, AppState s) {
    final next = s.allDone ? 0 : s.completed.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF6B5A9E), Color(0xFF423270)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: C.purple.withValues(alpha: .32),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12)),
            child: const Text('FOKUS HARI INI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
          ),
          const Spacer(),
          if (!s.focusMode)
            Text('${s.completed.length}/3',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
        ]),
        const SizedBox(height: 16),
        const Text('Tari Saman',
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
            s.allDone
                ? 'Semua variasi sudah tuntas!'
                : 'Lanjut Variasi ${Level.values[next].label}',
            style: TextStyle(
                color: Colors.white.withValues(alpha: .85), fontSize: 14)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: s.progress,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(C.orange),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: C.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0),
            onPressed: () {
              final label =
                  s.allDone ? 'Ulangi Latihan' : 'Lanjut Latihan';
              announceAction(
                  '$label. Membuka detail Variasi ${Level.values[next].label}');
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SamanDetailScreen(initial: next)));
            },
            icon: const Icon(Icons.play_arrow),
            label: Text(s.allDone ? 'Ulangi Latihan' : 'Lanjut Latihan',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  Widget _quickActions(BuildContext context, AppState s) => Row(children: [
        Expanded(
          child: _actionCard(
            icon: Icons.timer_outlined,
            label: 'Mode 2 Menit',
            sub: 'Pemanasan cepat',
            color: C.purpleSoft,
            iconColor: C.purple,
            onTap: () {
              announceAction(
                  'Mode Dua Menit dibuka. Latihan pemanasan selama dua menit');
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PracticeScreen(variationIndex: 0, mini: true)));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            icon: Icons.insights,
            label: 'Lihat Progress',
            sub: s.focusMode
                ? 'Lihat hasil latihanmu'
                : '${s.xp} XP • Lv ${s.level}',
            color: C.greenSoft,
            iconColor: C.green,
            onTap: () {
              announceAction('Membuka tab Progress');
              goTab(2);
            },
          ),
        ),
      ]);

  Widget _actionCard({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: C.ink)),
              const SizedBox(height: 3),
              Text(sub,
                  style: TextStyle(
                      color: C.ink.withValues(alpha: .65),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}