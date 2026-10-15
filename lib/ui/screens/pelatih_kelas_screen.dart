import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'create_sanggar_screen.dart';

class PelatihKelasScreen extends StatelessWidget {
  const PelatihKelasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final sg = s.currentSanggar;
        if (sg == null) return _emptyState(context);

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: AuthService.instance.streamMuridBySanggar(sg.id),
          builder: (context, snapshot) {
            final firestoreMurid = snapshot.data ?? [];
            final loading = snapshot.connectionState ==
                    ConnectionState.waiting &&
                !snapshot.hasData;

            return _buildBody(context, s, sg, firestoreMurid, loading);
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppState s,
    Sanggar sg,
    List<Map<String, dynamic>> firestoreMurid,
    bool loading,
  ) {
    final totalMurid = firestoreMurid.length;

    final totalMenit = firestoreMurid.fold<int>(
        0, (a, m) => a + ((m['totalMinutes'] ?? 0) as int));
    final avgStreak = firestoreMurid.isEmpty
        ? 0
        : (firestoreMurid.fold<int>(
                    0, (a, m) => a + ((m['streak'] ?? 0) as int)) /
                firestoreMurid.length)
            .round();

    final today = dayKey(DateTime.now());
    final sudahHariIni = firestoreMurid
        .where((m) => (m['lastDay'] ?? '') == today)
        .length;

    Map<String, dynamic>? palingAktif;
    for (final m in firestoreMurid) {
      final xp = (m['xp'] ?? 0) as int;
      if (palingAktif == null ||
          xp > ((palingAktif['xp'] ?? 0) as int)) {
        palingAktif = m;
      }
    }

    final perluPerhatian = firestoreMurid
        .where(_lamaTidakLatihanMap)
        .toList()
      ..sort((a, b) {
        final da = _daysSince(a['lastDay'] as String?) ?? 999;
        final db = _daysSince(b['lastDay'] as String?) ?? 999;
        return db.compareTo(da);
      });

    return Scaffold(
      backgroundColor: C.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            title: 'Kelas',
            subtitle:
                '${sg.name} • $totalMurid murid${loading ? " (memuat...)" : ""}',
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
                  menit: totalMenit,
                  avgStreak: avgStreak,
                  sudahHariIni: sudahHariIni,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Murid Paling Aktif',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
                        fg: C.red, bg: C.red.withValues(alpha: .12)),
                ]),
                const SizedBox(height: 10),
                _perluPerhatianCard(perluPerhatian),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- helpers ----

  static Widget _emptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: C.purpleSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_work_outlined,
                      size: 56, color: C.purple),
                ),
                const SizedBox(height: 20),
                const Text('Belum Punya Sanggar',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: C.ink)),
                const SizedBox(height: 8),
                const Text(
                  'Daftarkan sanggar kamu untuk mulai mengelola murid dan '
                  'membagikan modul latihan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: C.muted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: C.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateSanggarScreen(),
                        ),
                      );
                      if (result == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Sanggar berhasil didaftarkan!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_business,
                        color: Colors.white, size: 18),
                    label: const Text('Daftarkan Sanggar',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _lamaTidakLatihanMap(Map<String, dynamic> m) {
    final d = _daysSince(m['lastDay'] as String?);
    return d == null || d > 3;
  }

  static int? _daysSince(String? dayStr) {
    if (dayStr == null || dayStr.isEmpty) return null;
    try {
      final t = DateTime.now();
      final today = DateTime(t.year, t.month, t.day);
      final l = DateTime.parse(dayStr);
      return today.difference(DateTime(l.year, l.month, l.day)).inDays;
    } catch (_) {
      return null;
    }
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
      mainAxisExtent: 132,
      children: [
        _StatCard(
          icon: Icons.people_outline,
          label: 'Total Murid',
          value: '$murid',
          sub: 'online via kode',
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
          sub: 'dari $murid murid',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _palingAktifCard(Map<String, dynamic>? m) {
    if (m == null) {
      return _emptyCard(
        icon: Icons.emoji_events_outlined,
        title: 'Belum ada murid',
        sub: 'Bagikan kode sanggar biar murid gabung',
      );
    }
    final name = (m['nama'] ?? 'Siswa').toString();
    final xp = (m['xp'] ?? 0) as int;
    final streak = (m['streak'] ?? 0) as int;
    final totalMinutes = (m['totalMinutes'] ?? 0) as int;
    final d = _daysSince(m['lastDay'] as String?);
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
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                '$xp XP • $streak streak • ${_formatMenit(totalMinutes)}',
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

  Widget _perluPerhatianCard(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return _emptyCard(
        icon: Icons.check_circle_outline,
        title: 'Semua murid aktif',
        sub: 'Tidak ada yang perlu diingatkan minggu ini',
      );
    }
    return Column(children: [
      for (final m in list.take(5)) ...[
        _perhatianTile(m),
        const SizedBox(height: 8),
      ],
    ]);
  }

  Widget _perhatianTile(Map<String, dynamic> m) {
    final name = (m['nama'] ?? 'Siswa').toString();
    final d = _daysSince(m['lastDay'] as String?);
    final label =
        d == null ? 'Belum pernah latihan' : '$d hari tanpa latihan';
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
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: C.muted, fontSize: 11.5)),
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
              icon: const Icon(Icons.copy,
                  color: Colors.white, size: 18),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            'Siswa input kode ini di Search → Sanggar untuk gabung.',
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
                      fontSize: 10, height: 1.15, color: C.muted)),
            ],
          ),
        ],
      ),
    );
  }
}