import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'shell.dart';

/// Layar lengkapi profil — muncul setelah Google Sign-In pertama kali.
class CompleteProfileScreen extends StatefulWidget {
  final User firebaseUser;
  const CompleteProfileScreen({super.key, required this.firebaseUser});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _namaCtrl = TextEditingController();
  final _sanggarCtrl = TextEditingController();
  final _kodeCtrl = TextEditingController();
  String _role = 'siswa';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill nama dari Google
    _namaCtrl.text = widget.firebaseUser.displayName ?? '';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _sanggarCtrl.dispose();
    _kodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      _snack('Nama wajib diisi');
      return;
    }
    if (_role == 'pelatih' && _sanggarCtrl.text.trim().isEmpty) {
      _snack('Nama sanggar wajib diisi untuk Pelatih');
      return;
    }
    setState(() => _loading = true);

    // Simpan ke Firestore
    final ok = await AuthService.instance.saveUserProfile(
      nama: nama,
      role: _role,
      sanggarName: _role == 'pelatih' ? _sanggarCtrl.text.trim() : '',
      kodeSanggar: _role == 'siswa' ? _kodeCtrl.text.trim() : null,
    );

    if (!ok) {
      setState(() => _loading = false);
      _snack('Gagal simpan profil. Coba lagi.');
      return;
    }

    // Capture navigator SEBELUM async gap
    // ignore: use_build_context_synchronously
    final navigator = Navigator.of(context);

    // Simpan lokal juga
    await AppState.instance.createProfile(
      userName: nama,
      role: _role,
      sanggarName: _role == 'pelatih' ? _sanggarCtrl.text.trim() : '',
      kodeSanggar: _role == 'siswa' ? _kodeCtrl.text.trim() : null,
    );

    if (!mounted) return;
    // ignore: use_build_context_synchronously
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const Shell()),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                IconButton(
                  onPressed: () async {
                    await AuthService.instance.signOut();
                    // ignore: use_build_context_synchronously
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              ]),
              const SizedBox(height: 12),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: C.purpleSoft,
                  backgroundImage: widget.firebaseUser.photoURL != null
                      ? NetworkImage(widget.firebaseUser.photoURL!)
                      : null,
                  child: widget.firebaseUser.photoURL == null
                      ? const Icon(Icons.person,
                          size: 40, color: C.purple)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Hai, ${widget.firebaseUser.displayName ?? "Sahabat"}! 👋',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: C.ink),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text('Satu langkah lagi buat mulai belajar tari',
                    style: TextStyle(color: C.muted, fontSize: 13)),
              ),
              const SizedBox(height: 28),

              // Nama
              _label('Nama'),
              const SizedBox(height: 8),
              _textField(_namaCtrl, 'Nama lengkap', Icons.person_outline),
              const SizedBox(height: 20),

              // Role
              _label('Peran'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: _roleCard(
                    icon: Icons.school_outlined,
                    title: 'Siswa',
                    sub: 'Belajar tari',
                    selected: _role == 'siswa',
                    onTap: () => setState(() => _role = 'siswa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _roleCard(
                    icon: Icons.groups_outlined,
                    title: 'Pelatih',
                    sub: 'Kelola sanggar',
                    selected: _role == 'pelatih',
                    onTap: () => setState(() => _role = 'pelatih'),
                  ),
                ),
              ]),

              if (_role == 'pelatih') ...[
                const SizedBox(height: 20),
                _label('Nama Sanggar'),
                const SizedBox(height: 8),
                _textField(_sanggarCtrl, 'Nama sanggar kamu',
                    Icons.home_work_outlined),
                const SizedBox(height: 8),
                _infoBox(
                    'ID Sanggar akan dibuat otomatis. Share ID ke siswa untuk gabung.'),
              ],

              if (_role == 'siswa') ...[
                const SizedBox(height: 20),
                Row(children: [
                  _label('Kode Sanggar'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: C.line,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('opsional',
                        style: TextStyle(
                            fontSize: 10,
                            color: C.muted,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 8),
                _textField(_kodeCtrl, 'Kode dari pelatih (SANG-XXXX)',
                    Icons.vpn_key_outlined,
                    uppercase: true),
                const SizedBox(height: 8),
                _infoBox('Kosongkan kalau mau latihan mandiri tanpa sanggar.'),
              ],

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
                            Text('Simpan & Lanjutkan',
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

  Widget _label(String s) => Text(s,
      style: const TextStyle(
          color: C.ink, fontSize: 13.5, fontWeight: FontWeight.w700));

  Widget _textField(TextEditingController c, String hint, IconData icon,
          {bool uppercase = false}) =>
      TextField(
        controller: c,
        textCapitalization: uppercase
            ? TextCapitalization.characters
            : TextCapitalization.none,
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

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String sub,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? C.purpleSoft : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? C.purple : C.line,
                width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? C.purple : C.muted, size: 24),
              const SizedBox(height: 8),
              Text(title,
                  style: TextStyle(
                      color: selected ? C.purple : C.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              Text(sub,
                  style: const TextStyle(color: C.muted, fontSize: 11.5)),
            ],
          ),
        ),
      );

  Widget _infoBox(String text) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: C.purpleSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 16, color: C.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11.5,
                    color: C.purple.withValues(alpha: .8))),
          ),
        ]),
      );
}