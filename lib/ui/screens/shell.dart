import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'home_screen.dart';
import 'lessons_screen.dart';
import 'progress_screen.dart';
import 'sanggar_screen.dart';
import 'settings_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final isPelatih = s.isPelatih;

    // Tab adaptif berdasarkan role
    // Siswa: Home / Latihan / Progress / Settings
    // Pelatih: Home / Sanggar / Progress / Settings
    final pages = isPelatih
        ? [
            HomeScreen(goTab: (i) => setState(() => tab = i)),
            const SanggarScreen(),
            const ProgressScreen(),
            const SettingsScreen(),
          ]
        : [
            HomeScreen(goTab: (i) => setState(() => tab = i)),
            const LessonsScreen(),
            const ProgressScreen(),
            const SettingsScreen(),
          ];

    final destinations = isPelatih
        ? const [
            NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Learn'),
            NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Sanggar'),
            NavigationDestination(
                icon: Icon(Icons.show_chart),
                selectedIcon: Icon(Icons.insights),
                label: 'Progress'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings'),
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

    return Scaffold(
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: destinations,
      ),
    );
  }
}
