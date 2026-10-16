import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/screen_announcer.dart';
import '../widgets/shell_animation.dart';
import 'home_screen.dart';
import 'lessons_screen.dart';
import 'progress_screen.dart';
import 'pelatih_kelas_screen.dart';
import 'pelatih_murid_screen.dart';
import 'settings_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with SingleTickerProviderStateMixin {
  int tab = 0;

  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  static const Map<String, Map<String, String>> _tabInfo = {
    'siswa': {
      'Beranda':
          'Di bagian atas ada sapaan nama kamu, kolom pencarian, dan tombol '
          'lonceng notifikasi. Di tengah ada kartu Tari Saman berisi progress '
          'tiga variasi, dan tombol Lanjut Latihan atau Ulangi Latihan. '
          'Di bawah ada dua tombol cepat: Mode Dua Menit dan Lihat Progress.',
      'Latihan':
          'Ada tiga kartu variasi: Variasi Pemula, Variasi Menengah, dan '
          'Variasi Mahir. Setiap kartu menampilkan jumlah gerakan, durasi, '
          'dan jumlah selipan. Ketuk salah satu kartu untuk membuka detail.',
      'Progress': 'Ada tiga tab di atas: Streak, Waktu, dan Status.',
      'Pengaturan':
          'Ada bagian Profil, Ukuran Tulisan, Aksesibilitas, Mode Aplikasi, '
          'Sanggar Saya, Pengingat Harian, Kamera, Suara, tombol Hapus Semua '
          'Kemajuan Latihan, dan tombol Keluar dari Akun.',
    },
    'pelatih': {
      'Kelas':
          'Statistik murid, kode sanggar, dan murid yang perlu perhatian.',
      'Murid':
          'Daftar murid di sanggar kamu dengan progress masing-masing.',
      'Pengaturan':
          'Profil, aksesibilitas, mode aplikasi, info sanggar, dan logout.',
    },
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1,
    );

    _slide = Tween<double>(begin: 36, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _announceTab(tab);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _announceTab(int index) {
    final s = AppState.instance;
    final isPelatihUI = s.isPelatih && !s.isOffline;
    final roleKey = isPelatihUI ? 'pelatih' : 'siswa';

    final tabs = isPelatihUI
        ? ['Kelas', 'Murid', 'Pengaturan']
        : ['Beranda', 'Latihan', 'Progress', 'Pengaturan'];

    if (index < 0 || index >= tabs.length) return;
    final tabName = tabs[index];
    final summary = _tabInfo[roleKey]?[tabName];

    announcePage(context, title: tabName, summary: summary);
  }

  void _onTab(int i) {
    if (i == tab) return;
    final reduce = AppState.instance.reduceMotion;
    setState(() => tab = i);
    if (reduce) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward(from: 0);
    }
    _announceTab(i);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    // Pelatih di mode offline → jadi siswa UI
    final isPelatih = s.isPelatih && !s.isOffline;

    final pages = isPelatih
        ? const [
            PelatihKelasScreen(),
            PelatihMuridScreen(),
            SettingsScreen(),
          ]
        : [
            HomeScreen(goTab: _onTab),
            const LessonsScreen(),
            const ProgressScreen(),
            const SettingsScreen(),
          ];

    // Kalau jumlah tab menyusut (misal pelatih → siswa) dan index tab
    // sekarang out of range → reset ke 0
    final maxTab = pages.length;
    if (tab >= maxTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && tab >= maxTab) {
          setState(() => tab = 0);
        }
      });
    }

    final destinations = isPelatih
        ? const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Kelas'),
            NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Murid'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Pengaturan'),
          ]
        : const [
            NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Learn'),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Latihan'),
            NavigationDestination(
                icon: Icon(Icons.show_chart),
                selectedIcon: Icon(Icons.insights),
                label: 'Progress'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings'),
          ];

    return ShellAnimation(
      controller: _ctrl,
      slide: _slide,
      fade: _fade,
      child: Scaffold(
        body: IndexedStack(index: tab, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: _onTab,
          destinations: destinations,
        ),
      ),
    );
  }
}