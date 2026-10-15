import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/shell_animation.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'shell.dart';
import 'search_screen.dart';
import 'create_sanggar_screen.dart';

// ============================================================
// DATA AKSESIBILITAS
// ============================================================
class _AccOption {
  final String key;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String infoTitle;
  final String infoBody;
  const _AccOption({
    required this.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.infoTitle,
    required this.infoBody,
  });
}

const List<_AccOption> _accOptions = [
  _AccOption(
    key: 'dyslexia',
    icon: Icons.text_fields,
    color: C.purple,
    title: 'Tulisan ramah disleksia',
    subtitle: 'Huruf lebih jelas & jarak antar huruf lebih lega',
    infoTitle: 'Tulisan Ramah Disleksia',
    infoBody:
        'Cocok untuk kamu yang huruf-hurufnya kadang suka tertukar atau '
        'susah dibedakan (misalnya b dan d).\n\n'
        'Saat fitur ini dinyalakan:\n'
        '• Jenis huruf diganti ke yang lebih jelas\n'
        '• Jarak antar huruf lebih lebar\n'
        '• Baris tulisan tidak berdempetan\n\n'
        'Tidak ada salahnya dicoba — kalau tidak nyaman, bisa dimatikan '
        'lagi kapan saja.',
  ),
  _AccOption(
    key: 'lowVision',
    icon: Icons.format_bold,
    color: Colors.teal,
    title: 'Tulisan lebih tebal & kontras',
    subtitle: 'Tulisan jadi lebih tebal, warna lebih gelap',
    infoTitle: 'Tulisan Lebih Tebal & Kontras',
    infoBody:
        'Cocok kalau tulisan tipis terasa susah dibaca, atau warnanya '
        'terasa pudar.\n\n'
        'Saat fitur ini dinyalakan:\n'
        '• Tulisan jadi lebih tebal\n'
        '• Warna tulisan lebih gelap & kontras\n'
        '• Lebih mudah dibaca di cahaya terang\n\n'
        'Untuk mengatur ukuran tulisan, gunakan bagian "Ukuran Tulisan" '
        'di atas.',
  ),
  _AccOption(
    key: 'reduceMotion',
    icon: Icons.motion_photos_off_outlined,
    color: Colors.deepOrange,
    title: 'Kurangi gerakan',
    subtitle: 'Matikan animasi supaya tampilan lebih tenang',
    infoTitle: 'Kurangi Gerakan',
    infoBody:
        'Cocok kalau kamu gampang pusing, tidak nyaman, atau sensitif '
        'terhadap gerakan dan kilatan cahaya.\n\n'
        'Saat fitur ini dinyalakan:\n'
        '• Semua animasi & efek gerak dimatikan\n'
        '• Halaman berganti langsung tanpa transisi\n'
        '• Tidak ada efek slide, bounce, atau kedip\n\n'
        'Sangat membantu untuk yang punya sensitivitas terhadap cahaya '
        'atau gerakan.',
  ),
  _AccOption(
    key: 'colorBlind',
    icon: Icons.palette_outlined,
    color: Colors.pink,
    title: 'Bantu bedakan warna',
    subtitle: 'Pilih tipe yang paling cocok untuk matamu',
    infoTitle: 'Bantu Bedakan Warna',
    infoBody:
        'Cocok untuk yang sulit membedakan warna tertentu.\n\n'
        'Cara pakai:\n'
        '1. Nyalakan tombol\n'
        '2. Pilih tipe yang paling cocok (Merah / Hijau / Biru-Kuning)\n'
        '3. Lihat pratinjau warna di bawah — pilih yang paling mudah '
        'kamu bedakan\n\n'
        'Kalau tidak yakin tipemu yang mana, coba satu-satu dan pilih '
        'yang paling nyaman.',
  ),
  _AccOption(
    key: 'simpleMode',
    icon: Icons.center_focus_strong,
    color: Colors.blueGrey,
    title: 'Mode Sederhana',
    subtitle: 'Tampilan lebih ringkas, tanpa distraksi',
    infoTitle: 'Mode Sederhana',
    infoBody:
        'Cocok kalau kamu gampang terdistraksi atau sulit mempertahankan '
        'perhatian.\n\n'
        'Saat fitur ini dinyalakan:\n'
        '• Tampilan jadi lebih ringkas & sederhana\n'
        '• Pelajaran yang belum bisa dibuka disembunyikan\n'
        '• Statistik & lencana disembunyikan sementara\n'
        '• Pengaturan aksesibilitas jadi ikon saja\n'
        '• Fokus ke satu langkah berikutnya\n\n'
        'Tidak ada yang hilang — semua data tetap tersimpan dan akan '
        'muncul lagi kalau fitur ini dimatikan.',
  ),
];

bool _isAccActive(AppState s, String key) {
  switch (key) {
    case 'dyslexia':
      return s.dyslexiaFont;
    case 'lowVision':
      return s.lowVision;
    case 'reduceMotion':
      return s.reduceMotion;
    case 'colorBlind':
      return s.colorBlind;
    case 'simpleMode':
      return s.focusMode;
    default:
      return false;
  }
}

void _setAccActive(AppState s, String key, bool v) {
  s.update(() {
    switch (key) {
      case 'dyslexia':
        s.dyslexiaFont = v;
        break;
      case 'lowVision':
        s.lowVision = v;
        break;
      case 'reduceMotion':
        s.reduceMotion = v;
        break;
      case 'colorBlind':
        s.colorBlind = v;
        break;
      case 'simpleMode':
        s.focusMode = v;
        break;
    }
  });
}

// ============================================================
// SETTINGS SCREEN
// ============================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _fpsOptions = <int, String>{
    15: 'Hemat',
    24: 'Sedang',
    30: 'Halus',
    60: 'Sangat halus',
  };

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ListView(padding: EdgeInsets.zero, children: [
        const GradientHeader(
          title: 'Pengaturan',
          subtitle: 'Semua data tersimpan di HP kamu',
        ),
        SlideUpFade(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(children: [
              // === PROFIL ===
              _section('Profil', [
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                        color: C.purpleSoft, shape: BoxShape.circle),
                    child: Icon(
                        s.isPelatih
                            ? Icons.groups_outlined
                            : Icons.school_outlined,
                        color: C.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                              s.isPelatih
                                  ? 'Pelatih • ${s.currentSanggar?.name ?? "-"}'
                                  : (s.inSanggar
                                      ? 'Siswa • ${s.currentSanggar?.name ?? "-"}'
                                      : 'Belajar sendiri'),
                              style: const TextStyle(
                                  color: C.muted, fontSize: 12.5)),
                        ]),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: s.name,
                  decoration: InputDecoration(
                      labelText: 'Nama panggilan',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: C.bg),
                  onChanged: (v) => s.update(
                      () => s.name = v.trim().isEmpty ? 'Penari' : v.trim()),
                ),
              ]),
              const SizedBox(height: 12),

              // === UKURAN TULISAN ===
              _section('Ukuran Tulisan', [
                _TextScaleCard(s: s),
              ]),
              const SizedBox(height: 12),

              // === AKSESIBILITAS ===
              _section(
                'Aksesibilitas',
                s.focusMode
                    ? [_CompactAccGrid(s: s)]
                    : [
                        for (final opt in _accOptions) ...[
                          _AccessibilityTile(
                            opt: opt,
                            value: _isAccActive(s, opt.key),
                            onChanged: (v) => _setAccActive(s, opt.key, v),
                          ),
                          const SizedBox(height: 10),
                          if (opt.key == 'colorBlind' && s.colorBlind) ...[
                            _ColorBlindTypePicker(s: s),
                            const SizedBox(height: 10),
                          ],
                        ],
                        _PreviewCard(s: s),
                      ],
              ),
              const SizedBox(height: 12),

              // === MODE APLIKASI ===
              _section('Mode Aplikasi', [
                _tapRow(
                  title: 'Mode saat ini',
                  trailing: s.isOffline ? 'Offline' : 'Online',
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Text(
                            'Ganti ke Mode ${s.isOffline ? "Online" : "Offline"}?'),
                        content: Text(s.isOffline
                            ? 'Diperlukan internet & login. Fitur online akan aktif.'
                            : 'Fitur online akan dinonaktifkan. Latihan tetap bisa dilakukan.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal')),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Ganti')),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    final goOffline = !s.isOffline;
                    await s.setUserMode(goOffline ? 'offline' : 'online');
                    if (!context.mounted) return;
                    if (goOffline) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const Shell()),
                        (route) => false,
                      );
                    } else {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ]),
              const SizedBox(height: 12),

              // === SANGGAR SAYA (khusus siswa) ===
              if (!s.isPelatih) ...[
                _section('Sanggar Saya', [
                  if (s.inSanggar)
                    _tapRow(
                      title: s.currentSanggar?.name ?? 'Sanggar',
                      trailing: 'Keluar',
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: const Text('Keluar dari sanggar?'),
                            content: Text(
                                'Kamu akan keluar dari ${s.currentSanggar?.name ?? "sanggar"}. Progres tetap tersimpan.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal')),
                              FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: C.red),
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Keluar')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await s.setSanggarId(null);
                        }
                      },
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Belum gabung sanggar. Gabung untuk dapat modul & pantauan pelatih.',
                        style: TextStyle(
                            color: C.muted, fontSize: 12, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: C.purple,
                          side: const BorderSide(color: C.purple),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (s.isOffline) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Butuh Mode Online untuk cari sanggar.')),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SearchScreen()),
                          );
                        },
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Cari Sanggar',
                            style: TextStyle(
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 12),
              ],

              // === PENGINGAT (khusus siswa) ===
              if (!s.isPelatih) ...[
                _section('Pengingat Harian', [
                  _switchRow(
                    title: 'Ingatkan saya untuk latihan',
                    sub: 'Setiap hari jam ${s.reminderLabel}',
                    value: s.reminderOn,
                    onChanged: (v) => s.update(() => s.reminderOn = v),
                  ),
                  _tapRow(
                    title: 'Atur jam pengingat',
                    trailing: s.reminderLabel,
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                              hour: s.reminderHour,
                              minute: s.reminderMinute));
                      if (t != null) {
                        s.update(() {
                          s.reminderHour = t.hour;
                          s.reminderMinute = t.minute;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: s.habitCue,
                    decoration: InputDecoration(
                        labelText: 'Saya akan latihan setelah ...',
                        hintText: 'Contoh: pulang sekolah, makan malam',
                        helperText:
                            'Kaitkan dengan kegiatan harianmu supaya latihan gampang diingat',
                        helperMaxLines: 2,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: C.bg),
                    onChanged: (v) => s.update(() => s.habitCue = v),
                  ),
                ]),
                const SizedBox(height: 12),

                _section('Kamera', [
                  const Text('Kehalusan gambar kamera',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                      'Makin halus, gerakanmu makin teliti terbaca, tapi baterai lebih cepat habis. Kalau HP terasa panas, pilih yang lebih hemat.',
                      style: TextStyle(
                          color: C.muted, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: C.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: C.line)),
                    child: Row(
                      children: [
                        for (final e in _fpsOptions.entries)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => s.update(() => s.fps = e.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: s.fps == e.key
                                      ? C.purple
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(e.value,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: s.fps == e.key
                                              ? Colors.white
                                              : C.ink,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                _section('Suara', [
                  _switchRow(
                    title: 'Bunyi ketukan',
                    sub: 'Ada bunyi "tik" untuk menjaga irama gerakan',
                    value: s.metronome,
                    onChanged: (v) => s.update(() => s.metronome = v),
                  ),
                  _switchRow(
                    title: 'Suara pemandu',
                    sub: 'Ada suara yang memandu gerakan saat latihan',
                    value: s.voiceGuide,
                    onChanged: (v) => s.update(() => s.voiceGuide = v),
                  ),
                ]),
                const SizedBox(height: 12),
              ],

              // === INFO SANGGAR (pelatih) ===
              if (s.isPelatih) ...[
                if (s.currentSanggar == null)
                  _section('Sanggar', [
                    _tapRow(
                      title: 'Daftarkan Sanggar Baru',
                      trailing: 'Mulai',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateSanggarScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Daftarkan sanggar kamu untuk bisa kelola murid & share modul.',
                      style: TextStyle(
                          color: C.muted, fontSize: 12, height: 1.4),
                    ),
                  ])
                else
                  _section('Info Sanggar', [
                    _tapRow(
                      title: 'Nama sanggar',
                      trailing: s.currentSanggar?.name ?? '-',
                      onTap: () {},
                    ),
                    _tapRow(
                      title: 'Kode sanggar',
                      trailing: 'Salin',
                      onTap: () async {
                        final kode = s.currentSanggar?.id ?? '';
                        if (kode.isEmpty) return;
                        await Clipboard.setData(ClipboardData(text: kode));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Kode "$kode" disalin ke clipboard')),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: C.purpleSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.vpn_key,
                            size: 18, color: C.purple),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Kode untuk dibagikan ke murid:',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: C.muted,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(s.currentSanggar?.id ?? '-',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: C.purple,
                                      letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bagikan kode ini ke murid supaya mereka bisa bergabung ke sanggar kamu.',
                      style: TextStyle(
                          color: C.muted, fontSize: 12, height: 1.4),
                    ),
                  ]),
              ],

              const SizedBox(height: 24),

              if (!s.isPelatih) ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: C.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                                color: C.red.withValues(alpha: .3)))),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Hapus Semua Kemajuan Latihan',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Hapus semua kemajuan?',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17)),
                          content: const Text(
                              'Hari beruntun, poin (XP), lencana, dan variasi yang sudah selesai akan dihapus. Data yang sudah dihapus tidak bisa dikembalikan.'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Batal')),
                            FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: C.red),
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Hapus')),
                          ],
                        ),
                      );
                      if (ok == true) await s.resetProgress();
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                      foregroundColor: C.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: C.purple.withValues(alpha: .3)))),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Keluar dari Akun',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('Keluar dari akun?',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 17)),
                        content: const Text(
                            'Data latihan kamu tetap tersimpan. Kamu bisa masuk lagi dengan nama yang sama.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal')),
                          FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: C.purple),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Keluar')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await s.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Versi 1.0.0 • Bisa dipakai tanpa internet',
                  style: TextStyle(color: C.muted, fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.line),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 12),
              ...children,
            ]),
      );

  Widget _switchRow({
    required String title,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text(sub,
                      style: const TextStyle(color: C.muted, fontSize: 12)),
                ]),
          ),
          Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: C.purple),
        ]),
      );

  Widget _tapRow({
    required String title,
    required String trailing,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5)),
            ),
            Text(trailing,
                style: const TextStyle(
                    color: C.purple, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: C.muted),
          ]),
        ),
      );
}

// ============================================================
// TEXT SCALE CARD — slider ukuran tulisan
// ============================================================
class _TextScaleCard extends StatelessWidget {
  final AppState s;
  const _TextScaleCard({required this.s});

  static const double _min = 0.85;
  static const double _max = 1.5;

  String _label(double v) {
    if (v < 0.95) return 'Kecil';
    if (v < 1.10) return 'Normal';
    if (v < 1.25) return 'Besar';
    if (v < 1.40) return 'Sangat Besar';
    return 'Ekstra Besar';
  }

  @override
  Widget build(BuildContext context) {
    final v = s.textScale;
    final isDefault = (v - 1.0).abs() < 0.001;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: label + reset
        Row(
          children: [
            const Expanded(
              child: Text(
                'Atur besar tulisan sesuai nyamannya kamu',
                style: TextStyle(
                    fontSize: 12.5, color: C.muted, height: 1.4),
              ),
            ),
            if (!isDefault)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => s.update(() => s.textScale = 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 14, color: C.purple),
                        const SizedBox(width: 4),
                        Text(
                          'Reset',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: C.purple,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Preview box — teks akan otomatis ikut scale dari MaterialApp
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: C.purpleSoft.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.purple.withValues(alpha: .15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: C.purple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(v * 100).round()}% • ${_label(v)}',
                      style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Belajar tari jadi lebih nyaman dibaca.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Geser slider di bawah untuk mengubah ukuran.',
                style: TextStyle(color: C.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Slider
        Row(
          children: [
            // Ikon A kecil
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: C.line),
              ),
              child: const Text('A',
                  style: TextStyle(fontSize: 11, color: C.muted)),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: C.purple,
                  inactiveTrackColor: C.line,
                  thumbColor: C.purple,
                  overlayColor: C.purple.withValues(alpha: .12),
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20),
                ),
                child: Slider(
                  value: v,
                  min: _min,
                  max: _max,
                  divisions: ((_max - _min) / 0.05).round(),
                  onChanged: (val) =>
                      s.update(() => s.textScale = val),
                ),
              ),
            ),
            // Ikon A besar
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: C.line),
              ),
              child: const Text('A',
                  style: TextStyle(fontSize: 18, color: C.ink)),
            ),
          ],
        ),

        // Labels kiri-kanan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kecil',
                  style: TextStyle(fontSize: 10.5, color: C.muted)),
              Text('Ekstra Besar',
                  style: TextStyle(fontSize: 10.5, color: C.muted)),
            ],
          ),
        ),

        // Kalau lowVision aktif, kasih hint
        if (s.lowVision) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: C.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.line),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: C.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode "Tulisan lebih tebal & kontras" juga aktif. '
                    'Kamu bisa kombinasikan dengan ukuran di atas.',
                    style: TextStyle(
                        fontSize: 11, color: C.muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// FULL TILE
// ============================================================
class _AccessibilityTile extends StatelessWidget {
  final _AccOption opt;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AccessibilityTile({
    required this.opt,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? opt.color.withValues(alpha: .06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? opt.color.withValues(alpha: .4) : C.line,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: opt.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(opt.icon, color: opt.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      opt.subtitle,
                      style: const TextStyle(
                          color: C.muted, fontSize: 11.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              _InfoButton(
                onTap: () => _showInfo(context),
                color: opt.color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ToggleButton(
            value: value,
            color: opt.color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        titlePadding: EdgeInsets.zero,
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: opt.color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(opt.icon, color: opt.color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              opt.infoTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          opt.infoBody,
          style: const TextStyle(
              fontSize: 13, height: 1.55, color: C.ink),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: opt.color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPACT GRID
// ============================================================
class _CompactAccGrid extends StatelessWidget {
  final AppState s;
  const _CompactAccGrid({required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: C.bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 13, color: C.muted),
              const SizedBox(width: 6),
              Text(
                'Ketuk ikon untuk atur',
                style: TextStyle(
                    fontSize: 11, color: C.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CompactTile(s: s, opt: _accOptions[0]),
            const SizedBox(width: 56),
            _CompactTile(s: s, opt: _accOptions[1]),
          ],
        ),
        const SizedBox(height: 14),
        _CompactTile(s: s, opt: _accOptions[2]),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CompactTile(s: s, opt: _accOptions[3]),
            const SizedBox(width: 56),
            _CompactTile(s: s, opt: _accOptions[4]),
          ],
        ),
      ],
    );
  }
}

class _CompactTile extends StatelessWidget {
  final AppState s;
  final _AccOption opt;
  const _CompactTile({required this.s, required this.opt});

  @override
  Widget build(BuildContext context) {
    final active = _isAccActive(s, opt.key);
    return Semantics(
      button: true,
      toggled: active,
      label: '${opt.title}, ${active ? "aktif" : "nonaktif"}',
      child: GestureDetector(
        onTap: () => _showCompactDetail(context, s, opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: [
                      opt.color,
                      Color.lerp(opt.color, Colors.black, 0.18)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: active
                  ? Colors.transparent
                  : opt.color.withValues(alpha: .3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? opt.color.withValues(alpha: .3)
                    : Colors.black.withValues(alpha: .04),
                blurRadius: active ? 16 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            opt.icon,
            color: active ? Colors.white : opt.color,
            size: 30,
          ),
        ),
      ),
    );
  }
}

Future<void> _showCompactDetail(
    BuildContext context, AppState s, _AccOption opt) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CompactDetailSheet(s: s, opt: opt),
  );
}

class _CompactDetailSheet extends StatelessWidget {
  final AppState s;
  final _AccOption opt;
  const _CompactDetailSheet({required this.s, required this.opt});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final active = _isAccActive(s, opt.key);
        final showCbPicker = opt.key == 'colorBlind' && active;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: C.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: opt.color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(opt.icon, color: opt.color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt.infoTitle,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    opt.infoBody,
                    style: const TextStyle(
                        fontSize: 13, height: 1.55, color: C.ink),
                  ),
                  if (showCbPicker) ...[
                    const SizedBox(height: 16),
                    _ColorBlindTypePicker(s: s),
                  ],
                  const SizedBox(height: 20),
                  _ToggleButton(
                    value: active,
                    color: opt.color,
                    onChanged: (v) => _setAccActive(s, opt.key, v),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// TOGGLE BUTTON
// ============================================================
class _ToggleButton extends StatelessWidget {
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _ToggleButton({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      label: value
          ? 'Aktif, ketuk untuk mematikan'
          : 'Nonaktif, ketuk untuk menyalakan',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 44,
            decoration: BoxDecoration(
              gradient: value
                  ? LinearGradient(
                      colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.15)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: value ? null : C.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value ? Colors.transparent : C.line,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    value ? Icons.check_circle : Icons.circle_outlined,
                    key: ValueKey(value),
                    color: value ? Colors.white : C.muted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value
                      ? 'Aktif — ketuk untuk matikan'
                      : 'Ketuk untuk aktifkan',
                  style: TextStyle(
                    color: value ? Colors.white : C.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: .2,
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

// ============================================================
// INFO BUTTON
// ============================================================
class _InfoButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const _InfoButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Penjelasan fitur',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: .35)),
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: color,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PREVIEW CARD
// ============================================================
class _PreviewCard extends StatelessWidget {
  final AppState s;
  const _PreviewCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final none = !s.dyslexiaFont &&
        !s.lowVision &&
        !s.reduceMotion &&
        !s.colorBlind &&
        !s.focusMode;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.purpleSoft.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.purple.withValues(alpha: .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined,
                  size: 15, color: C.purple.withValues(alpha: .8)),
              const SizedBox(width: 6),
              Text(
                'Pratinjau',
                style: TextStyle(
                    fontSize: 11,
                    color: C.purple.withValues(alpha: .85),
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _swatch(const Color(0xFFD96060), 'Merah'),
              _swatch(const Color(0xFF4FA878), 'Hijau'),
              _swatch(const Color(0xFFED9848), 'Oranye'),
              _swatch(const Color(0xFF5D4B8C), 'Ungu'),
            ],
          ),
          if (none) ...[
            const SizedBox(height: 10),
            const Text(
              'Nyalakan salah satu fitur di atas untuk melihat perbedaannya.',
              style: TextStyle(color: C.muted, fontSize: 11.5, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _swatch(Color c, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 9.5, color: C.muted)),
        ],
      ),
    );
  }
}

// ============================================================
// COLOR BLIND TYPE PICKER
// ============================================================
class _ColorBlindTypePicker extends StatelessWidget {
  final AppState s;
  const _ColorBlindTypePicker({required this.s});

  static const _options = <_CbOption>[
    _CbOption(
      key: 'protan',
      label: 'Merah',
      hint: 'Sulit bedakan merah dan hijau',
      swatch: Color(0xFFD96060),
    ),
    _CbOption(
      key: 'deutan',
      label: 'Hijau',
      hint: 'Paling umum. Sulit bedakan hijau & merah',
      swatch: Color(0xFF4FA878),
    ),
    _CbOption(
      key: 'tritan',
      label: 'Biru-Kuning',
      hint: 'Sulit bedakan biru dan kuning',
      swatch: Color(0xFF4A80D9),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 14, color: C.muted),
              const SizedBox(width: 6),
              const Text(
                'Pilih tipe yang paling cocok',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: C.muted,
                    letterSpacing: .3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _options.length; i++) ...[
            _optionTile(context, _options[i]),
            if (i < _options.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _optionTile(BuildContext context, _CbOption opt) {
    final selected = s.colorBlindType == opt.key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => s.update(() => s.colorBlindType = opt.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? C.purple : Colors.transparent,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: opt.swatch.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: opt.swatch,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      opt.hint,
                      style: const TextStyle(
                          color: C.muted, fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? C.purple : Colors.transparent,
                  border: Border.all(
                    color: selected ? C.purple : C.line,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CbOption {
  final String key;
  final String label;
  final String hint;
  final Color swatch;
  const _CbOption({
    required this.key,
    required this.label,
    required this.hint,
    required this.swatch,
  });
}