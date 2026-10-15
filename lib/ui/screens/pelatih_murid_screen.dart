import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell_animation.dart';
import 'murid_detail_screen.dart';

class PelatihMuridScreen extends StatefulWidget {
  const PelatihMuridScreen({super.key});
  @override
  State<PelatihMuridScreen> createState() => _PelatihMuridScreenState();
}

class _PelatihMuridScreenState extends State<PelatihMuridScreen> {
  final _namaCtrl = TextEditingController();

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  void _tambahSiswa() {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      _snack('Nama siswa tidak boleh kosong');
      return;
    }
    final s = AppState.instance;
    final sg = s.currentSanggar;
    if (sg == null) {
      _snack('Sanggar tidak ditemukan');
      return;
    }
    if (sg.siswa.contains(nama)) {
      _snack('"$nama" sudah ada di daftar');
      return;
    }
    s.addSiswa(nama);
    _namaCtrl.clear();
    FocusScope.of(context).unfocus();
    _snack('✅ $nama ditambahkan');
  }

  Future<void> _kickMurid(String uid, String nama) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluarkan murid?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
            '"$nama" akan dikeluarkan dari sanggar. Progres murid tetap tersimpan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluarkan')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await AuthService.instance.kickMurid(uid);
    if (!mounted) return;
    _snack(res ? '✅ $nama dikeluarkan' : '❌ Gagal mengeluarkan');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

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

        return Scaffold(
          backgroundColor: C.bg,
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: AuthService.instance.streamMuridBySanggar(sg.id),
            builder: (context, snapshot) {
              final firestoreMurid = snapshot.data ?? [];
              final loading = snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData;

              final rows = _buildRows(s, sg, firestoreMurid);

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  GradientHeader(
                    title: 'Murid',
                    subtitle: '${rows.length} murid di ${sg.name}',
                  ),
                  SlideUpFade(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tambahForm(),
                          const SizedBox(height: 20),
                          Row(children: [
                            const Expanded(
                              child: Text('Daftar Murid',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ),
                            if (loading)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: C.purple),
                              )
                            else
                              Pill('${rows.length}',
                                  fg: C.purple, bg: C.purpleSoft),
                          ]),
                          const SizedBox(height: 10),
                          if (rows.isEmpty)
                            _emptyCard()
                          else
                            for (final r in rows) ...[
                              _muridTile(r),
                              const SizedBox(height: 8),
                            ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // DATA MERGE: Firestore + Lokal
  // ============================================================
  List<_MuridRow> _buildRows(
    AppState s,
    Sanggar sg,
    List<Map<String, dynamic>> firestoreMurid,
  ) {
    final localProfiles = s.muridProfiles;
    final rows = <_MuridRow>[];
    final seenUids = <String>{};
    final seenNames = <String>{};

    // 1. Dari Firestore (murid yang gabung via kode)
    for (final m in firestoreMurid) {
      final uid = (m['uid'] ?? '').toString();
      final nama = (m['nama'] ?? 'Siswa').toString();
      if (uid.isEmpty) continue;

      // Coba match dengan profil lokal (kalau ada)
      UserData? localProfile;
      for (final p in localProfiles) {
        if (p.name.toLowerCase() == nama.toLowerCase()) {
          localProfile = p;
          break;
        }
      }

      rows.add(_MuridRow(
        uid: uid,
        name: nama,
        profile: localProfile,
        inSanggarList: true,
        xp: (m['xp'] ?? 0) as int,
        streak: (m['streak'] ?? 0) as int,
        totalMinutes: (m['totalMinutes'] ?? 0) as int,
        completedCount: (m['completedCount'] ?? 0) as int,
        lastDay: m['lastDay'] as String?,
        fromFirestore: true,
      ));
      seenUids.add(uid);
      seenNames.add(nama.toLowerCase());
    }

    // 2. Dari AppState lokal (kalau ada yang belum ke-sync)
    for (final p in localProfiles) {
      final namaLower = p.name.toLowerCase();
      if (seenNames.contains(namaLower)) continue;

      rows.add(_MuridRow(
        uid: '',
        name: p.name,
        profile: p,
        inSanggarList: false,
        xp: p.xp,
        streak: p.streak,
        totalMinutes: p.totalMinutes,
        completedCount: p.completed.length,
        lastDay: p.lastDay,
        fromFirestore: false,
      ));
      seenNames.add(namaLower);
    }

    // 3. Dari list nama manual (sg.siswa)
    for (final n in sg.siswa) {
      if (seenNames.contains(n.toLowerCase())) continue;
      rows.add(_MuridRow(
        uid: '',
        name: n,
        profile: null,
        inSanggarList: true,
        xp: 0,
        streak: 0,
        totalMinutes: 0,
        completedCount: 0,
        lastDay: null,
        fromFirestore: false,
      ));
      seenNames.add(n.toLowerCase());
    }

    // Sort: by XP desc
    rows.sort((a, b) => b.xp.compareTo(a.xp));
    return rows;
  }

  // ============================================================
  // UI PIECES
  // ============================================================
  Widget _tambahForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.person_add_alt_1, color: C.purple, size: 20),
            SizedBox(width: 8),
            Text('Tambah Murid Manual',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _namaCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _tambahSiswa(),
                decoration: InputDecoration(
                  hintText: 'Nama murid',
                  filled: true,
                  fillColor: C.bg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.line)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: C.purple, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: C.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _tambahSiswa,
                child: const Text('Tambah',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          const Text(
            'Murid yang gabung lewat kode sanggar akan otomatis muncul di daftar ini dengan progres lengkap.',
            style: TextStyle(fontSize: 11, color: C.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _muridTile(_MuridRow r) {
    final initial = r.name.isNotEmpty ? r.name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: r.fromFirestore ? C.purpleSoft : C.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                initial,
                style: TextStyle(
                    color: r.fromFirestore ? C.purple : C.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(r.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    if (r.fromFirestore) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: C.green.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('online',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color:
                                    C.green.withValues(alpha: .9))),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    'Level ${(r.xp ~/ 100) + 1} • ${r.xp} XP',
                    style: const TextStyle(
                        color: C.muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (r.uid.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: C.purple, size: 18),
                tooltip: 'Lihat detail',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MuridDetailScreen(
                      murid: {
                        'uid': r.uid,
                        'nama': r.name,
                        'xp': r.xp,
                        'streak': r.streak,
                        'longest': r.profile?.longest ?? r.streak,
                        'totalMinutes': r.totalMinutes,
                        'completedCount': r.completedCount,
                        'lastDay': r.lastDay,
                        'badges': r.profile?.badges.toList() ?? [],
                        'secondsByDay': r.profile?.secondsByDay ?? {},
                      },
                    ),
                  ),
                ),
              ),
            if (r.uid.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.person_remove_outlined,
                    color: C.red, size: 20),
                tooltip: 'Keluarkan dari sanggar',
                onPressed: () => _kickMurid(r.uid, r.name),
              )
            else if (r.inSanggarList)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: C.red, size: 20),
                onPressed: () {
                  AppState.instance.removeSiswa(r.name);
                  _snack('"${r.name}" dihapus');
                },
              ),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(children: [
            _miniStat(Icons.local_fire_department_outlined,
                '${r.streak}', 'streak', Colors.orange),
            _miniStat(Icons.timer_outlined,
                _formatMenit(r.totalMinutes), 'latihan', Colors.teal),
            _miniStat(Icons.menu_book_outlined,
                '${r.completedCount}', 'variasi', C.purple),
          ]),
        ],
      ),
    );
  }

  Widget _miniStat(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13)),
        Text(label,
            style: const TextStyle(color: C.muted, fontSize: 10.5)),
      ]),
    );
  }

  Widget _emptyCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.line),
        ),
        child: Column(children: [
          const Icon(Icons.people_outline, size: 56, color: C.line),
          const SizedBox(height: 12),
          const Text('Belum ada murid',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: C.muted,
                  fontSize: 14)),
          const SizedBox(height: 4),
          const Text(
            'Bagikan kode sanggar ke murid,\natau tambahkan manual lewat form di atas',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.muted, fontSize: 12),
          ),
        ]),
      );

  static String _formatMenit(int m) {
    if (m <= 0) return '0';
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}j' : '${h}j${r}m';
  }
}

class _MuridRow {
  final String uid;
  final String name;
  final UserData? profile;
  final bool inSanggarList;
  final int xp;
  final int streak;
  final int totalMinutes;
  final int completedCount;
  final String? lastDay;
  final bool fromFirestore;

  _MuridRow({
    required this.uid,
    required this.name,
    required this.profile,
    required this.inSanggarList,
    required this.xp,
    required this.streak,
    required this.totalMinutes,
    required this.completedCount,
    required this.lastDay,
    required this.fromFirestore,
  });
}