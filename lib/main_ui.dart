import 'package:flutter/material.dart';
import 'ui/no_stretch_scroll_behavior.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/shell.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/state/app_state.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.load();
  runApp(const TariAppUI());
}

class TariAppUI extends StatelessWidget {
  const TariAppUI({super.key});
  @override
  Widget build(BuildContext context) {
    final loggedIn = AppState.instance.hasLoggedIn;
    return MaterialApp(
      title: 'Belajar Bareng (UI)',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scrollBehavior: const NoStretchScrollBehavior(),
      home: SplashScreen(
        next: loggedIn ? const Shell() : const LoginScreen(),
      ),
    );
  }
}