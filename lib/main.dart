import 'package:flutter/material.dart';

import 'ai/ai_service.dart';
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
  // ignore: discarded_futures
  AiService.instance.initialize();

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
      home: SplashScreen(
        next: loggedIn ? const Shell() : const LoginScreen(),
      ),
    );
  }
}
