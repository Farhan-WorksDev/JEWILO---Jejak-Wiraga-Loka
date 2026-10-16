import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/screen_announcer.dart';
import 'login_screen.dart';
import 'shell.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  void _selectOnline(BuildContext context) {
    // Tidak set mode di sini — LoginScreen yang akan set setelah login sukses.
    // Pakai push biasa (bukan pushReplacement) supaya tombol back di
    // LoginScreen bisa balik ke sini.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _selectOffline(BuildContext context) async {
    final s = AppState.instance;
    await s.setUserMode('offline');
    if (!s.hasLoggedIn) {
      await s.createProfile(userName: 'Tamu', role: 'siswa');
    }
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Shell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenAnnouncer(
      title: 'Pilih Mode',
      summary:
          'Ada dua pilihan. Mode Online untuk daftar akun dan gabung sanggar. '
          'Mode Offline untuk langsung latihan tanpa akun. '
          'Ketuk salah satu kartu untuk memilih.',
      child: Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: C.purpleSoft,
                    ),
                    child: const Icon(Icons.self_improvement,
                        size: 56, color: C.purple),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text('JEWILO',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: C.ink)),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text('Jejak • Wiraga • Loka',
                      style: TextStyle(color: C.muted, fontSize: 13)),
                ),
                const SizedBox(height: 40),
                const Text('Pilih Mode:',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: C.ink)),
                const SizedBox(height: 12),
                _ModeCard(
                  icon: Icons.cloud_done_outlined,
                  color: C.purple,
                  softColor: C.purpleSoft,
                  title: 'Mode Online',
                  subtitle: 'Daftar akun, gabung sanggar, sinkron progres',
                  features: const [
                    'Progres tersimpan di akun',
                    'Gabung sanggar tari',
                    'Cari sanggar di seluruh Indonesia',
                    'Pelatih bisa pantau murid',
                  ],
                  onTap: () => _selectOnline(context),
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.offline_bolt_outlined,
                  color: C.orange,
                  softColor: C.orangeSoft,
                  title: 'Mode Offline',
                  subtitle: 'Langsung latihan tanpa daftar akun',
                  features: const [
                    'Tanpa daftar, langsung pakai',
                    'Progres disimpan di HP',
                    'Latihan kamera + AI',
                    'Semua data 100% offline',
                  ],
                  onTap: () => _selectOffline(context),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Mode bisa diubah nanti di Pengaturan',
                    style: TextStyle(
                        color: C.muted.withValues(alpha: .8),
                        fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color softColor;
  final String title;
  final String subtitle;
  final List<String> features;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.color,
    required this.softColor,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: .3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: C.ink)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: C.muted)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: color),
              ]),
              const SizedBox(height: 14),
              for (final f in features) ...[
                Row(children: [
                  Icon(Icons.check_circle, size: 14, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f,
                        style: const TextStyle(fontSize: 12, color: C.ink)),
                  ),
                ]),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}