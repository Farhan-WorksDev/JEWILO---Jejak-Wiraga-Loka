import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class CreateSanggarScreen extends StatefulWidget {
  const CreateSanggarScreen({super.key});
  @override
  State<CreateSanggarScreen> createState() => _CreateSanggarScreenState();
}

class _CreateSanggarScreenState extends State<CreateSanggarScreen> {
  final _namaCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _jadwalCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _tahunCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _regionCtrl.dispose();
    _alamatCtrl.dispose();
    _teleponCtrl.dispose();
    _emailCtrl.dispose();
    _jadwalCtrl.dispose();
    _deskripsiCtrl.dispose();
    _tahunCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nama = _namaCtrl.text.trim();
    final region = _regionCtrl.text.trim();
    if (nama.isEmpty) {
      _snack('Nama sanggar wajib diisi');
      return;
    }
    if (region.isEmpty) {
      _snack('Wilayah wajib diisi');
      return;
    }
    setState(() => _loading = true);

    final result = await AuthService.instance.createSanggar(
      nama: nama,
      region: region,
      alamat: _alamatCtrl.text.trim(),
      telepon: _teleponCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      jadwal: _jadwalCtrl.text.trim(),
      deskripsi: _deskripsiCtrl.text.trim(),
      tahunBerdiri: int.tryParse(_tahunCtrl.text.trim()),
      tarian: const ['Saman'],
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] != true) {
      _snack(result['message'] ?? 'Gagal buat sanggar');
      return;
    }

    // Update AppState lokal
    await AppState.instance.setAsPelatih(
      sanggarId: result['sanggarId'],
      sanggarName: nama,
      kode: result['kode'],
    );

    if (!mounted) return;

    // Tampil dialog sukses + kode
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sanggar berhasil dibuat! 🎉',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bagikan kode ini ke murid supaya mereka bisa gabung:',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.purpleSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  result['kode'] ?? '-',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: C.purple,
                      letterSpacing: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Kode juga bisa dilihat di Pengaturan.',
                style: TextStyle(color: C.muted, fontSize: 11.5)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        title: const Text('Daftarkan Sanggar',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: C.ink, fontSize: 17)),
        iconTheme: const IconThemeData(color: C.ink),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoBanner(),
              const SizedBox(height: 20),
              _label('Nama Sanggar *'),
              _textField(_namaCtrl, 'Contoh: Sanggar Seni Nusantara',
                  Icons.home_work_outlined),
              const SizedBox(height: 16),
              _label('Wilayah *'),
              _textField(_regionCtrl, 'Contoh: Padang, Sumatera Barat',
                  Icons.location_on_outlined),
              const SizedBox(height: 16),
              _label('Alamat'),
              _textField(_alamatCtrl, 'Jl. Contoh No. 123',
                  Icons.map_outlined),
              const SizedBox(height: 16),
              _label('Telepon'),
              _textField(_teleponCtrl, '0812-3456-7890', Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 16),
              _label('Email'),
              _textField(_emailCtrl, 'sanggar@email.com',
                  Icons.email_outlined,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _label('Tahun Berdiri'),
              _textField(_tahunCtrl, '2010', Icons.calendar_today_outlined,
                  keyboard: TextInputType.number),
              const SizedBox(height: 16),
              _label('Jadwal Latihan'),
              _textField(_jadwalCtrl, 'Senin & Rabu 16:00-18:00',
                  Icons.schedule_outlined),
              const SizedBox(height: 16),
              _label('Deskripsi'),
              TextField(
                controller: _deskripsiCtrl,
                maxLines: 3,
                style: const TextStyle(color: C.ink),
                decoration: InputDecoration(
                  hintText: 'Ceritakan tentang sanggar kamu...',
                  hintStyle: TextStyle(
                      color: C.muted.withValues(alpha: .7)),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: C.line)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: C.purple, width: 1.5)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: C.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Daftarkan Sanggar',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Colors.white)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward,
                                size: 18, color: Colors.white),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.purpleSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 18, color: C.purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Setelah didaftarkan, kamu akan dapat kode unik untuk dibagikan ke murid.',
              style: TextStyle(
                  fontSize: 12,
                  color: C.purple.withValues(alpha: .9),
                  height: 1.4),
            ),
          ),
        ]),
      );

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s,
            style: const TextStyle(
                color: C.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700)),
      );

  Widget _textField(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
  }) =>
      TextField(
        controller: c,
        keyboardType: keyboard,
        style: const TextStyle(color: C.ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: C.muted.withValues(alpha: .7)),
          prefixIcon: Icon(icon, color: C.muted, size: 20),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: C.line)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: C.purple, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}