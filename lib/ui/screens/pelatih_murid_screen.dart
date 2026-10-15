import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell_animation.dart';

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

  Future<void> _hapusSiswa(String nama) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus murid?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text('"$nama" akan dihapus dari daftar sanggar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      AppState.instance.removeSiswa(nama);
      if (!mounted) return;
      _snack('"$nama" dihapus');
    }
  }

  void _snack(String msg) {
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

        final rows = _buildRows(s, sg);

        return Scaffold(
          backgroundColor: C.bg,
          body: ListView(
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
          ),
        );
      },
    );
  }

  // ============================================================
  // DATA
  // ============================================================
  List<_MuridRow> _buildRows(AppState s, Sanggar sg) {
    final profiles = s.muridProfiles;
    final rows = <_MuridRow>[];
    final seen = <String>{};

    for (final p in profiles) {
      rows.add(_MuridRow(name: p.name, profile: p, inSanggarList: false));
      seen.add(p.name.toLowerCase());
    }
    for (final n in sg.siswa) {
      if (seen.contains(n.toLowerCase())) {
        for (var i = 0; i < rows.length; i++) {
          if (rows[i].name.toLowerCase() == n.toLowerCase()) {
            rows[i] = _MuridRow(
              name: rows[i].name,
              profile: rows[i].profile,
              inSanggarList: true,
            );
            break;
          }
        }
      } else {
        rows.add(_MuridRow(name: n, profile: null, inSanggarList: true));
      }
    }

    // Sort: yang punya profil dulu (by XP desc), lalu nama
    rows.sort((a, b) {
      if ((a.profile == null) != (b.profile == null)) {
        return a.profile == null ? 1 : -1;
      }
      if (a.profile != null && b.profile != null) {
        return b.profile!.xp.compareTo(a.profile!.xp);
      }
      return a.name.compareTo(b.name);
    });
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
            Text('Tambah Murid Baru',
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
    final p = r.profile;
    final hasProfile = p != null;

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
                color: hasProfile ? C.purpleSoft : C.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: hasProfile ? C.purple : C.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    hasProfile
                        ? 'Level ${(p.xp ~/ 100) + 1} • ${p.xp} XP'
                        : 'Belum punya profil',
                    style: const TextStyle(
                        color: C.muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (r.inSanggarList)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: C.red, size: 20),
                onPressed: () => _hapusSiswa(r.name),
              ),
          ]),
          if (hasProfile) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              _miniStat(
                  Icons.local_fire_department_outlined,
                  '${p.streak}',
                  'streak',
                  Colors.orange),
              _miniStat(Icons.timer_outlined,
                  _formatMenit(p.totalMinutes), 'latihan', Colors.teal),
              _miniStat(Icons.menu_book_outlined,
                  '${p.completed.length}', 'variasi', C.purple),
            ]),
          ],
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
          Icon(Icons.people_outline, size: 56, color: C.line),
          const SizedBox(height: 12),
          const Text('Belum ada murid',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: C.muted,
                  fontSize: 14)),
          const SizedBox(height: 4),
          const Text(
            'Tambahkan murid lewat form di atas,\natau bagikan kode sanggar',
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
  final String name;
  final UserData? profile;
  final bool inSanggarList;
  _MuridRow({
    required this.name,
    required this.profile,
    required this.inSanggarList,
  });
}