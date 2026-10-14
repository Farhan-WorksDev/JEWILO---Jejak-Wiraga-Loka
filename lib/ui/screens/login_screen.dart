import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showCreateForm = false;

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Shell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AppState.instance,
          builder: (context, _) {
            final s = AppState.instance;
            final users = s.allUsers;
            return SingleChildScrollView(
              child: Column(
                children: [
                  _header(),
                  if (!_showCreateForm && users.isNotEmpty)
                    _profileList(users)
                  else
                    _createForm(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [C.purpleDark, C.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .15),
              border: Border.all(
                  color: Colors.white.withValues(alpha: .3), width: 2),
            ),
            child: const Icon(Icons.self_improvement,
                size: 52, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text('Belajar Bareng',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Eksplorasi Seni Tari Nusantara',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .75),
                  fontSize: 13)),
        ]),
      );

  // ============================================================
  // LIST PROFIL EXISTING
  // ============================================================
  Widget _profileList(List<UserData> users) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                child: Text('Pilih Profil',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              Text('${users.length} profil',
                  style: const TextStyle(color: C.muted, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            for (final u in users) ...[
              _userTile(u),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: C.purple,
                    side: const BorderSide(color: C.purple),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () => setState(() => _showCreateForm = true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Profil Baru',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                  'Semua data disimpan di HP kamu • 100% offline',
                  style: TextStyle(
                      color: C.muted.withValues(alpha: .8), fontSize: 11.5)),
            ),
          ],
        ),
      );

  Widget _userTile(UserData u) => GestureDetector(
        onTap: () async {
          await AppState.instance.loginAs(u.id);
          if (!mounted) return;
          _goToHome();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: C.purpleSoft, shape: BoxShape.circle),
              child: Icon(
                  u.role == 'pelatih'
                      ? Icons.groups_outlined
                      : Icons.school_outlined,
                  color: C.purple,
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(
                        u.role == 'pelatih'
                            ? 'Pelatih'
                            : 'Siswa • Lv ${u.xp ~/ 100 + 1} • ${u.xp} XP',
                        style: const TextStyle(
                            color: C.muted, fontSize: 12)),
                  ]),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: C.muted),
          ]),
        ),
      );

  // ============================================================
  // FORM CREATE PROFIL BARU
  // ============================================================
  Widget _createForm() {
    final hasUsers = AppState.instance.users.isNotEmpty;
    return _CreateProfileForm(
      showBack: hasUsers,
      onCancel: () => setState(() => _showCreateForm = false),
      onSuccess: _goToHome,
    );
  }
}

// ============================================================
// FORM STATE
// ============================================================
class _CreateProfileForm extends StatefulWidget {
  final bool showBack;
  final VoidCallback onCancel;
  final VoidCallback onSuccess;
  const _CreateProfileForm({
    required this.showBack,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  State<_CreateProfileForm> createState() => _CreateProfileFormState();
}

class _CreateProfileFormState extends State<_CreateProfileForm> {
  final _namaCtrl = TextEditingController();
  final _sanggarCtrl = TextEditingController();
  final _kodeCtrl = TextEditingController();
  String _role = 'siswa';
  bool _loading = false;

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
    setState(() => _loading = true);
    try {
      await AppState.instance.createProfile(
        userName: nama,
        role: _role,
        sanggarName: _role == 'pelatih' ? _sanggarCtrl.text.trim() : '',
        kodeSanggar: _role == 'siswa' ? _kodeCtrl.text.trim() : null,
      );
      if (!mounted) return;
      widget.onSuccess();
    } catch (e) {
      setState(() => _loading = false);
      _snack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (widget.showBack)
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.arrow_back),
              ),
            if (widget.showBack) const SizedBox(width: 4),
            const Text('Buat Profil Baru',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 17)),
          ]),
          const SizedBox(height: 20),
          _label('Nama Kamu'),
          const SizedBox(height: 8),
          _textField(_namaCtrl, 'Nama lengkap kamu', Icons.person_outline),
          const SizedBox(height: 20),
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

          // Pelatih: nama sanggar
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

          // Siswa: kode sanggar (opsional)
          if (_role == 'siswa') ...[
            const SizedBox(height: 20),
            Row(children: [
              _label('Kode Sanggar'),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            _infoBox(
                'Kosongkan kalau mau latihan mandiri tanpa sanggar.'),
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
                        Text('Buat & Masuk',
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
