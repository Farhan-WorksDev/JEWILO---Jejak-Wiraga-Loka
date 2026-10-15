import 'package:flutter/material.dart';

import 'ui/no_stretch_scroll_behavior.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/shell.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/services/reminder_service.dart';
import 'ui/state/app_state.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.load();
  // ignore: discarded_futures
  ReminderService.instance.init();
  // Kamera + AI TIDAK dinyalakan di sini lagi. Dinyalakan hanya saat masuk
  // layar latihan (PracticeScreen) dan dimatikan saat keluar.

  runApp(const TariApp());
}

class TariApp extends StatelessWidget {
  const TariApp({super.key});
  @override
  Widget build(BuildContext context) {
    final loggedIn = AppState.instance.hasLoggedIn;
    return MaterialApp(
      title: 'Belajar Bareng - Tari Saman',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scrollBehavior: const NoStretchScrollBehavior(),
      home: SplashScreen(
        next: loggedIn ? const Shell() : const LoginScreen(),
      ),
    );
  }
}