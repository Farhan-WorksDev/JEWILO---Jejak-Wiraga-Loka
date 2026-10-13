import 'package:flutter/material.dart';

/// Palet warna aplikasi — versi MEDIUM SOFT.
/// Soft & nyaman, tapi kontras tetap terjaga (gak washed out).
class C {
  // === UNGU UTAMA (pekat cukup, tapi kalem) ===
  static const purple = Color(0xFF5D4B8C);
  static const purpleDark = Color(0xFF423270);
  static const purpleSoft = Color(0xFFEBE4F7);

  // === ORANYE (hangat, hidup tapi gak nyala) ===
  static const orange = Color(0xFFED9848);
  static const orangeSoft = Color(0xFFFFF0DC);

  // === HIJAU (medium, gak neon) ===
  static const green = Color(0xFF4FA878);
  static const greenSoft = Color(0xFFE1F3E9);

  // === BIRU soft ===
  static const blueSoft = Color(0xFFE7EFFB);

  // === NEUTRAL ===
  static const bg = Color(0xFFF5F2FA);
  static const ink = Color(0xFF2A2440);
  static const muted = Color(0xFF6E6885);
  static const line = Color(0xFFE5DEF2);

  // === AKSEN ===
  static const red = Color(0xFFD96060);
  static const redSoft = Color(0xFFFAE5E5);
  static const gold = Color(0xFFE8B860);
  static const fire = Color(0xFFED9848);
  static const fireDeep = Color(0xFFD96060);

  // === LAYAR LATIHAN ===
  static const darkBg = Color(0xFF2C2444);
  static const darkBgDeep = Color(0xFF1A142E);
  static const success = Color(0xFF6BC494);
  static const glowPurple = Color(0xFFA896D8);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.purple,
      primary: C.purple,
      surface: C.bg,
    ),
    scaffoldBackgroundColor: C.bg,
  );
  final tt = base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink);
  return base.copyWith(
    textTheme: tt.copyWith(
      displayLarge: tt.displayLarge?.copyWith(fontWeight: FontWeight.w800),
      displayMedium: tt.displayMedium?.copyWith(fontWeight: FontWeight.w800),
      displaySmall: tt.displaySmall?.copyWith(fontWeight: FontWeight.w800),
      headlineLarge: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      bodySmall: tt.bodySmall?.copyWith(fontWeight: FontWeight.w400),
      labelLarge: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: tt.labelSmall?.copyWith(fontWeight: FontWeight.w500),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: C.purpleSoft,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
