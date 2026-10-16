import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'complete_profile_screen.dart';
import 'shell.dart';

/// Login screen — Google only.
/// Setelah auth → cek Firestore:
///   - Ada profil → Shell
///   - Belum ada → CompleteProfileScreen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.instance.signInWithGoogle();
      if (user == null) {
        _snack('Google Sign-In dibatalkan');
        return;
      }
      // Cek Firestore: apakah user udah punya profil?
      final profile = await AuthService.instance.getUserProfile();
      if (!mounted) return;

      if (profile != null && profile['nama'] != null) {
        // User lama → langsung ke Shell
        await AppState.instance.createProfile(
          userName: profile['nama'],
          role: profile['role'] ?? 'siswa',
          sanggarName: profile['sanggarName'] ?? '',
          kodeSanggar: profile['kodeSanggar'],
        );

        // Sync sanggarId dari Firestore ke lokal (kalau ada)
        final remoteSanggarId = profile['sanggarId'] as String?;
        if (remoteSanggarId != null && remoteSanggarId.isNotEmpty) {
          await AppState.instance.setSanggarId(remoteSanggarId);
        }

        // Attach Firestore listener (handle kick murid real-time)
        AppState.instance.listenToMyFirestoreDoc();

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Shell()),
        );
      } else {
        // User baru → Complete Profile
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(firebaseUser: user),
          ),
        );
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  const Text(
                    'Masuk untuk sinkron progres & gabung sanggar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: C.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: C.ink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: C.line)),
                        elevation: 0,
                      ),
                      onPressed: _loading ? null : _signIn,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.g_mobiledata,
                              size: 32, color: Color(0xFF4285F4)),
                      label: Text(_loading ? 'Memuat...' : 'Masuk dengan Google',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dengan masuk, kamu setuju dengan Syarat & Ketentuan kami.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: C.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 32),
                  Container(
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
                          'Mau latihan tanpa akun? Balik dan pilih Mode Offline.',
                          style: TextStyle(
                              fontSize: 12,
                              color: C.purple.withValues(alpha: .9),
                              height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ],
          ),
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
          // Tombol back buat balik ke mode selection
          Row(children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ]),
          const SizedBox(height: 8),
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
          const Text('JEWILO',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Jejak • Wiraga • Loka',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .75),
                  fontSize: 13)),
        ]),
      );
}