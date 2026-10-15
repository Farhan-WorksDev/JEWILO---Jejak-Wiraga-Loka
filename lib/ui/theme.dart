import 'package:flutter/material.dart';

/// Palet warna aplikasi — versi MEDIUM SOFT.
class C {
  static const purple = Color(0xFF5D4B8C);
  static const purpleDark = Color(0xFF423270);
  static const purpleSoft = Color(0xFFEBE4F7);

  static const orange = Color(0xFFED9848);
  static const orangeSoft = Color(0xFFFFF0DC);

  static const green = Color(0xFF4FA878);
  static const greenSoft = Color(0xFFE1F3E9);

  static const blueSoft = Color(0xFFE7EFFB);

  static const bg = Color(0xFFF5F2FA);
  static const ink = Color(0xFF2A2440);
  static const muted = Color(0xFF6E6885);
  static const line = Color(0xFFE5DEF2);

  static const red = Color(0xFFD96060);
  static const redSoft = Color(0xFFFAE5E5);
  static const gold = Color(0xFFE8B860);
  static const fire = Color(0xFFED9848);
  static const fireDeep = Color(0xFFD96060);

  static const darkBg = Color(0xFF2C2444);
  static const darkBgDeep = Color(0xFF1A142E);
  static const success = Color(0xFF6BC494);
  static const glowPurple = Color(0xFFA896D8);

  // Warna khusus mode Rabun Jauh (kontras lebih tinggi)
  static const inkHigh = Color(0xFF100A22);
  static const mutedHigh = Color(0xFF3A3350);
}

/// Bangun tema.
/// - `dyslexia: true` → font ramah disleksia + jarak huruf lega
/// - `lowVision: true` → warna lebih gelap + teks lebih tebal
/// - `reduceMotion: true` → matikan SEMUA animasi transisi route
ThemeData buildTheme({
  bool dyslexia = false,
  bool lowVision = false,
  bool reduceMotion = false,
}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.purple,
      primary: C.purple,
      surface: C.bg,
    ),
    scaffoldBackgroundColor: C.bg,
    fontFamily: dyslexia ? 'PlusJakartaSans' : null,
    // Mode Kurangi Gerakan → semua Navigator.push jadi instan
    pageTransitionsTheme: reduceMotion
        ? const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _NoAnimationTransitionsBuilder(),
              TargetPlatform.iOS: _NoAnimationTransitionsBuilder(),
              TargetPlatform.macOS: _NoAnimationTransitionsBuilder(),
              TargetPlatform.windows: _NoAnimationTransitionsBuilder(),
              TargetPlatform.linux: _NoAnimationTransitionsBuilder(),
              TargetPlatform.fuchsia: _NoAnimationTransitionsBuilder(),
            },
          )
        : null,
  );

  final bodyColor = lowVision ? C.inkHigh : C.ink;
  final tt = base.textTheme.apply(
    bodyColor: bodyColor,
    displayColor: bodyColor,
  );

  FontWeight boost(FontWeight w) {
    if (!lowVision) return w;
    if (w == FontWeight.w400) return FontWeight.w600;
    if (w == FontWeight.w500) return FontWeight.w700;
    if (w == FontWeight.w600) return FontWeight.w700;
    if (w == FontWeight.w700) return FontWeight.w800;
    if (w == FontWeight.w800) return FontWeight.w900;
    return w;
  }

  final styled = tt.copyWith(
    displayLarge:
        tt.displayLarge?.copyWith(fontWeight: boost(FontWeight.w800)),
    displayMedium:
        tt.displayMedium?.copyWith(fontWeight: boost(FontWeight.w800)),
    displaySmall:
        tt.displaySmall?.copyWith(fontWeight: boost(FontWeight.w800)),
    headlineLarge:
        tt.headlineLarge?.copyWith(fontWeight: boost(FontWeight.w800)),
    headlineMedium:
        tt.headlineMedium?.copyWith(fontWeight: boost(FontWeight.w800)),
    headlineSmall:
        tt.headlineSmall?.copyWith(fontWeight: boost(FontWeight.w800)),
    titleLarge:
        tt.titleLarge?.copyWith(fontWeight: boost(FontWeight.w700)),
    titleMedium:
        tt.titleMedium?.copyWith(fontWeight: boost(FontWeight.w600)),
    titleSmall:
        tt.titleSmall?.copyWith(fontWeight: boost(FontWeight.w600)),
    bodyLarge:
        tt.bodyLarge?.copyWith(fontWeight: boost(FontWeight.w400)),
    bodyMedium:
        tt.bodyMedium?.copyWith(fontWeight: boost(FontWeight.w400)),
    bodySmall:
        tt.bodySmall?.copyWith(fontWeight: boost(FontWeight.w400)),
    labelLarge:
        tt.labelLarge?.copyWith(fontWeight: boost(FontWeight.w600)),
    labelMedium:
        tt.labelMedium?.copyWith(fontWeight: boost(FontWeight.w600)),
    labelSmall:
        tt.labelSmall?.copyWith(fontWeight: boost(FontWeight.w500)),
  );

  final textTheme = dyslexia ? _applyDyslexiaSpacing(styled) : styled;

  return base.copyWith(
    textTheme: textTheme,
    pageTransitionsTheme: reduceMotion
        ? const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _NoAnimationTransitionsBuilder(),
              TargetPlatform.iOS: _NoAnimationTransitionsBuilder(),
              TargetPlatform.macOS: _NoAnimationTransitionsBuilder(),
              TargetPlatform.windows: _NoAnimationTransitionsBuilder(),
              TargetPlatform.linux: _NoAnimationTransitionsBuilder(),
              TargetPlatform.fuchsia: _NoAnimationTransitionsBuilder(),
            },
          )
        : null,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: C.purpleSoft,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

TextTheme _applyDyslexiaSpacing(TextTheme t) {
  TextStyle? fix(TextStyle? s) => s?.copyWith(
        letterSpacing: (s.letterSpacing ?? 0) + 0.5,
        height: 1.5,
      );
  return t.copyWith(
    displayLarge: fix(t.displayLarge),
    displayMedium: fix(t.displayMedium),
    displaySmall: fix(t.displaySmall),
    headlineLarge: fix(t.headlineLarge),
    headlineMedium: fix(t.headlineMedium),
    headlineSmall: fix(t.headlineSmall),
    titleLarge: fix(t.titleLarge),
    titleMedium: fix(t.titleMedium),
    titleSmall: fix(t.titleSmall),
    bodyLarge: fix(t.bodyLarge),
    bodyMedium: fix(t.bodyMedium),
    bodySmall: fix(t.bodySmall),
    labelLarge: fix(t.labelLarge),
    labelMedium: fix(t.labelMedium),
    labelSmall: fix(t.labelSmall),
  );
}

/// Transisi route tanpa animasi — halaman langsung tampil.
/// Dipakai saat mode "Kurangi gerakan" aktif.
class _NoAnimationTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}