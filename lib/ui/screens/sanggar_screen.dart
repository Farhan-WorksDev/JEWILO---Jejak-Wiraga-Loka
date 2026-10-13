import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SanggarScreen extends StatefulWidget {
  const SanggarScreen({super.key});
  @override
  State<SanggarScreen> createState() => _SanggarScreenState();
}

class _SanggarScreenState extends State<SanggarScreen> {
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
        title: const Text('Hapus siswa?',
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

  void _copyId() {
    final sg = AppState.instance.currentSanggar;
    if (sg == null) return;
    Clipboard.setData(ClipboardData(text: sg.id));
    _snack('✅ ID "${sg.id}" dicopy');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final sg = s.currentSanggar;

    if (sg == null) {
      return Scaffold(
        backgroundColor: C.bg,
        body: const Center(child: Text('Sanggar tidak ditemukan')),
      );
    }

    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            title: 'Sanggar',
            subtitle: '${sg.name} • ${sg.siswa.length} siswa',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============ ID SANGGAR CARD ============
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [C.purple, C.purpleDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.vpn_key_outlined,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text('ID SANGGAR',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                          child: Text(sg.id,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2)),
                        ),
                        IconButton(
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.white24),
                          onPressed: _copyId,
                          icon: const Icon(Icons.copy,
                              color: Colors.white, size: 18),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                          'Siswa input kode ini di Login untuk gabung ke sanggar kamu.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: .75),
                              fontSize: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ============ TAMBAH SISWA ============
                Container(
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
                        Icon(Icons.person_add_alt_1,
                            color: C.purple, size: 20),
                        SizedBox(width: 8),
                        Text('Tambah Siswa Baru',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                      ]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _namaCtrl,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _tambahSiswa(),
                              decoration: InputDecoration(
                                hintText: 'Nama siswa',
                                filled: true,
                                fillColor: C.bg,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: C.line)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: C.purple, width: 1.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: C.purple,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12))),
                              onPressed: _tambahSiswa,
                              child: const Text('Tambah',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ============ LIST SISWA ============
                Row(children: [
                  const Expanded(
                    child: Text('Daftar Siswa',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                  Pill('${sg.siswa.length} siswa',
                      fg: C.purple, bg: C.purpleSoft),
                ]),
                const SizedBox(height: 10),

                if (sg.siswa.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: C.line),
                    ),
                    child: Column(children: [
                      Icon(Icons.people_outline,
                          size: 56, color: C.line),
                      const SizedBox(height: 12),
                      const Text('Belum ada siswa',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: C.muted,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text(
                          'Tambahkan siswa lewat form di atas,\natau share ID sanggar',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: C.muted, fontSize: 12)),
                    ]),
                  )
                else
                  for (int i = 0; i < sg.siswa.length; i++) ...[
                    _siswaTile(i + 1, sg.siswa[i]),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _siswaTile(int no, String nama) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: C.purpleSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$no',
                style: const TextStyle(
                    color: C.purple,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                const Text('Siswa Sanggar',
                    style: TextStyle(color: C.muted, fontSize: 11.5)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: C.red, size: 20),
            onPressed: () => _hapusSiswa(nama),
          ),
        ]),
      );
}
