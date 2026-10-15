import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class PelatihKelasScreen extends StatelessWidget {
  const PelatihKelasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final sg = s.currentSanggar;
        if (sg == null) {
          return Scaffold(
            backgroundColor: C.bg,
            body: const Center(child: Text('Sanggar tidak ditemukan')),
          );
        }

        final profiles = s.muridProfiles;

        // Jumlah murid unik (gabungan nama di sg.siswa + profil yang gabung via kode)
        final names = <String>{};
        for (final p in profiles) {
          names.add(p.name.toLowerCase());
        }
        for (final n in sg.siswa) {
          names.add(n.toLowerCase());
        }
        final totalMurid = names.length;

        final totalMenit =
            profiles.fold<int>(0, (a, p) => a + p.totalMinutes);
        final avgStreak = profiles.isEmpty
            ? 0
            : (profiles.fold<int>(0, (a, p) => a + p.streak) /
                    profiles.length)
                .round();

        final today = dayKey(DateTime.now());
        final sudahHariIni = profiles
            .where((p) => (p.secondsByDay[today] ?? 0) > 0)
            .length;

        UserData? palingAktif;
        for (final p in profiles) {
          if (palingAktif == null || p.xp > palingAktif.xp) {
            palingAktif = p;
          }
        }

        final perluPerhatian = profiles.where(_lamaTidakLatihan).toList()
          ..sort((a, b) {
            final da = _daysSince(a.lastDay) ?? 999;
            final db = _daysSince(b.lastDay) ?? 999;
            return db.compareTo(da);
          });

        return Scaffold(
          backgroundColor: C.bg,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              GradientHeader(
                title: 'Kelas',
                subtitle: '${sg.name} • $totalMurid murid',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _KodeSanggarCard(sanggarId: sg.id),
                    const SizedBox(height: 20),
                    _statGrid(
                      murid: totalMurid,
                      withProfil: profiles.length,
                      menit: totalMenit,
                      avgStreak: avgStreak,
                      sudahHariIni: sudahHariIni,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Murid Paling Aktif',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    _palingAktifCard(palingAktif),
                    const SizedBox(height: 24),
                    Row(children: [
                      const Expanded(
                        child: Text(
                          'Perlu Perhatian',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      if (perluPerhatian.isNotEmpty)
                        Pill('${perluPerhatian.length}',
                            fg: C.red,
                            bg: C.red.withValues(alpha: .12)),
                    ]),
                    const SizedBox(height: 10),
                    _perluPerhatianCard(perluPerhatian),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- helpers ----

  static bool _lamaTidakLatihan(UserData u) {
    final d = _daysSince(u.lastDay);
    return d == null || d > 3;
  }

  static int? _daysSince(String? dayStr) {
    if (dayStr == null) return null;
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final l = DateTime.parse(dayStr);
    return today.difference(DateTime(l.year, l.month, l.day)).inDays;
  }

  static String _formatMenit(int m) {
    if (m <= 0) return '0 mnt';
    if (m < 60) return '$m mnt';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}j' : '${h}j ${r}m';
  }

  Widget _statGrid({
    required int murid,
    required int withProfil,
    required int menit,
    required int avgStreak,
    required int sudahHariIni,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      // Tinggi kartu fixed, biar gak overflow di lebar layar apapun
      mainAxisExtent: 132,
      children: [
        _StatCard(
          icon: Icons.people_outline,
          label: 'Total Murid',
          value: '$murid',
          sub: '$withProfil punya profil',
          color: C.purple,
        ),
        _StatCard(
          icon: Icons.timer_outlined,
          label: 'Total Latihan',
          value: _formatMenit(menit),
          sub: 'akumulasi semua murid',
          color: Colors.teal,
        ),
        _StatCard(
          icon: Icons.local_fire_department_outlined,
          label: 'Rata Streak',
          value: '$avgStreak hari',
          sub: 'aktif beruntun',
          color: Colors.orange,
        ),
        _StatCard(
          icon: Icons.bolt_outlined,
          label: 'Latihan Hari Ini',
          value: '$sudahHariIni',
          sub: 'dari $withProfil murid',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _palingAktifCard(UserData? u) {
    if (u == null) {
      return _emptyCard(
        icon: Icons.emoji_events_outlined,
        title: 'Belum ada murid dengan profil',
        sub: 'Murid yang gabung lewat kode akan muncul di sini',
      );
    }
    final d = _daysSince(u.lastDay);
    final lastLabel = d == null
        ? 'belum pernah latihan'
        : (d == 0 ? 'latihan hari ini' : '$d hari lalu');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [C.purple, C.purpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.emoji_events,
              color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(u.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                '${u.xp} XP • ${u.streak} streak • ${_formatMenit(u.totalMinutes)}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                lastLabel,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: .65),
                    fontSize: 11),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _perluPerhatianCard(List<UserData> list) {
    if (list.isEmpty) {
      return _emptyCard(
        icon: Icons.check_circle_outline,
        title: 'Semua murid aktif',
        sub: 'Tidak ada yang perlu diingatkan minggu ini',
      );
    }
    return Column(children: [
      for (final u in list.take(5)) ...[
        _perhatianTile(u),
        const SizedBox(height: 8),
      ],
    ]);
  }

  Widget _perhatianTile(UserData u) {
    final d = _daysSince(u.lastDay);
    final label = d == null ? 'Belum pernah latihan' : '$d hari tanpa latihan';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.red.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications_none,
              color: C.red, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(u.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(color: C.muted, fontSize: 11.5)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String sub,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.line),
      ),
      child: Column(children: [
        Icon(icon, size: 44, color: C.line),
        const SizedBox(height: 10),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: C.muted,
                fontSize: 13.5)),
        const SizedBox(height: 4),
        Text(sub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: C.muted, fontSize: 11.5)),
      ]),
    );
  }
}

// ============================================================
// SUB-WIDGETS
// ============================================================

class _KodeSanggarCard extends StatelessWidget {
  final String sanggarId;
  const _KodeSanggarCard({required this.sanggarId});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: sanggarId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Kode "$sanggarId" dicopy')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [C.purple, C.purpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.vpn_key_outlined,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('KODE SANGGAR',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('SHARE KE SISWA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Text(sanggarId,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
            ),
            IconButton(
              style:
                  IconButton.styleFrom(backgroundColor: Colors.white24),
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy, color: Colors.white, size: 18),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            'Siswa input kode ini di Login untuk gabung ke sanggar kamu.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: .75),
                fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 19,
                      height: 1.1,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      height: 1.15,
                      color: C.muted,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10,
                      height: 1.15,
                      color: C.muted)),
            ],
          ),
        ],
      ),
    );
  }
}