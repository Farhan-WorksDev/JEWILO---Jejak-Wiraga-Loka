import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Detail sanggar + tombol gabung real (validasi kode via Firestore).
class SanggarDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sanggar;
  const SanggarDetailScreen({super.key, required this.sanggar});

  @override
  State<SanggarDetailScreen> createState() => _SanggarDetailScreenState();
}

class _SanggarDetailScreenState extends State<SanggarDetailScreen> {
  final _kodeCtrl = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _kodeCtrl.dispose();
    super.dispose();
  }

  String get _name => widget.sanggar['name'] ?? 'Sanggar';
  String get _region => widget.sanggar['region'] ?? '-';
  String get _kode => widget.sanggar['kode'] ?? '-';
  String get _alamat => widget.sanggar['alamat'] ?? '-';
  String get _telepon => widget.sanggar['telepon'] ?? '-';
  String get _email => widget.sanggar['email'] ?? '-';
  String get _jadwal => widget.sanggar['jadwal'] ?? '-';
  String get _deskripsi => widget.sanggar['deskripsi'] ?? 'Belum ada deskripsi.';
  String get _tarian {
    final t = widget.sanggar['tarian'];
    if (t is List) return t.join(', ');
    return t?.toString() ?? '-';
  }

  int? get _tahun {
    final t = widget.sanggar['tahunBerdiri'];
    if (t is int) return t;
    return int.tryParse(t?.toString() ?? '');
  }

  Future<void> _join() async {
    final kode = _kodeCtrl.text.trim();
    if (kode.isEmpty) {
      _snack('Kode sanggar wajib diisi');
      return;
    }
    setState(() => _joining = true);
    final result = await AuthService.instance.joinSanggar(kode);
    if (!mounted) return;
    setState(() => _joining = false);

    if (result['success'] == true) {
      await AppState.instance.setSanggarId(result['sanggar']?['docId']);
      if (!mounted) return;
      _snack(result['message'] ?? 'Berhasil gabung!');
      Navigator.pop(context);
    } else {
      _snack(result['message'] ?? 'Gagal gabung');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text('Detail Sanggar',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _header(),
                const SizedBox(height: 20),
                _sectionInfo(),
                const SizedBox(height: 16),
                _sectionJadwal(),
                const SizedBox(height: 16),
                _sectionTentang(),
                const SizedBox(height: 24),
                _gabungBox(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [C.purpleDark, C.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.home_work,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(_region,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Tarian: $_tarian',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _sectionInfo() => _card(
        title: 'Informasi',
        icon: Icons.info_outline,
        children: [
          _row('Alamat', _alamat),
          _row('Telepon', _telepon),
          _row('Email', _email),
          if (_tahun != null) _row('Berdiri sejak', '$_tahun'),
          _row('Kode sanggar', _kode),
        ],
      );

  Widget _sectionJadwal() => _card(
        title: 'Jadwal Latihan',
        icon: Icons.calendar_today,
        children: [_row('Jadwal', _jadwal)],
      );

  Widget _sectionTentang() => _card(
        title: 'Tentang Sanggar',
        icon: Icons.auto_stories_outlined,
        children: [
          Text(_deskripsi,
              style: const TextStyle(
                  color: C.ink, fontSize: 13, height: 1.5)),
        ],
      );

  Widget _gabungBox() {
    final s = AppState.instance;
    if (s.isOffline) {
      return _infoBox(
          'Butuh Mode Online untuk gabung sanggar. Ganti dulu di Pengaturan.');
    }
    final already = s.currentSanggarId == widget.sanggar['docId'];
    if (already) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.green.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle, color: C.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Kamu sudah anggota sanggar ini',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: C.green.withValues(alpha: .9))),
          ),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Punya kode sanggar?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _kodeCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'SANG-XXXX',
            prefixIcon:
                const Icon(Icons.vpn_key_outlined, color: C.muted),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: C.line)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: C.line)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: C.purple, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: C.purple,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _joining ? null : _join,
          icon: _joining
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.login, color: Colors.white, size: 18),
          label: Text(_joining ? 'Memproses...' : 'Gabung Sanggar',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
      ],
    );
  }

  Widget _infoBox(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.orangeSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 18, color: C.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: C.orange.withValues(alpha: .9),
                    height: 1.4)),
          ),
        ]),
      );

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: C.purple, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style:
                      const TextStyle(color: C.muted, fontSize: 12.5)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: C.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}