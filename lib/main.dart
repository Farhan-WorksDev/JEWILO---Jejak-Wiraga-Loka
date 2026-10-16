import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'ui/color_filters.dart';
import 'ui/no_stretch_scroll_behavior.dart';
import 'ui/screens/mode_selection_screen.dart';
import 'ui/screens/shell.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/services/reminder_service.dart';
import 'ui/services/tts_service.dart';
import 'ui/state/app_state.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AppState.instance.load();

  // Init TTS (TalkBack)
  await TtsService.instance.init();

  // ignore: discarded_futures
  AppState.instance.listenToMyFirestoreDoc();
  // ignore: discarded_futures
  ReminderService.instance.init();
  runApp(const TariApp());
}

class TariApp extends StatelessWidget {
  const TariApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
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
            next: (s.hasLoggedIn || s.isOffline)
                ? const Shell()
                : const ModeSelectionScreen(),
          ),
        );
      },
    );
  }
}