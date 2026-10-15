import 'package:flutter/material.dart';
import '../state/app_state.dart';
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1, // value=1 → gak ada animasi saat pertama buka app
    );

    _slide = Tween<double>(begin: 36, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTab(int i) {
    if (i == tab) return;
    setState(() => tab = i);
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final isPelatih = s.isPelatih;

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