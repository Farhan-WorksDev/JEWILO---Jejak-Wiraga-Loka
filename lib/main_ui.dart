import 'package:flutter/material.dart';
import 'ui/color_filters.dart';
import 'ui/no_stretch_scroll_behavior.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/shell.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/services/tts_service.dart';
import 'ui/state/app_state.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.load();
  await TtsService.instance.init();
  runApp(const TariAppUI());
}

class TariAppUI extends StatelessWidget {
  const TariAppUI({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final loggedIn = s.hasLoggedIn;
        return MaterialApp(
          title: 'JEWILO - Jejak Wiraga Loka',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(
            dyslexia: s.dyslexiaFont,
            lowVision: s.lowVision,
            reduceMotion: s.reduceMotion,
          ),
          scrollBehavior: const NoStretchScrollBehavior(),
          builder: (context, child) {
            Widget result = child!;
            if (s.colorBlind) {
              final filter = ColorFilters.filterFor(s.colorBlindType);
              if (filter != null) {
                result = ColorFiltered(colorFilter: filter, child: result);
              }
            }
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(s.textScale),
                disableAnimations: s.reduceMotion,
              ),
              child: result,
            );
          },
          home: SplashScreen(
            next: loggedIn ? const Shell() : const LoginScreen(),
          ),
        );
      },
    );
  }
}