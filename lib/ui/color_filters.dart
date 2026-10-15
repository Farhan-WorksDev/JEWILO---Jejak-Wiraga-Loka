import 'package:flutter/widgets.dart';

/// Matriks koreksi warna untuk tiap tipe buta warna.
///
/// Prinsip aman:
/// - Setiap baris jumlahnya = 1 → putih tetap putih, hitam tetap hitam
/// - Tidak ada nilai ekstrem → tidak ada channel yang "bocor" jadi
///   warna aneh (mis. cyan)
/// - Tiap tipe menggeser warna yang sulit dibedakan ke hue yang
///   masih bisa dilihat oleh penderitanya.
class ColorFilters {
  ColorFilters._();

  /// Protanopia (merah lemah).
  /// Strategi: merah digeser ke arah pink/magenta — protan masih bisa
  /// lihat komponen biru, jadi merah yang "pink" lebih menonjol.
  /// Baris 3: R0.5 B0.5 → merah dapat tambahan biru (pink).
  static const List<double> protan = <double>[
    1.0, 0.0, 0.0, 0, 0, //
    0.0, 1.0, 0.0, 0, 0, //
    0.5, 0.0, 0.5, 0, 0, // merah → dapat sedikit biru (pink)
    0,   0,   0,   1, 0,
  ];

  /// Deuteranopia (hijau lemah) — tipe paling umum.
  /// Strategi: hijau digeser ke arah teal/biru-hijau — deutan masih
  /// bisa lihat komponen biru, jadi hijau yang "kebiruan" lebih
  /// menonjol dan tidak tertukar dengan merah.
  /// Baris 3: G0.5 B0.5 → hijau dapat tambahan biru (teal).
  static const List<double> deutan = <double>[
    1.0, 0.0, 0.0, 0, 0, //
    0.0, 1.0, 0.0, 0, 0, //
    0.0, 0.5, 0.5, 0, 0, // hijau → dapat sedikit biru (teal)
    0,   0,   0,   1, 0,
  ];

  /// Tritanopia (biru-kuning) — jarang.
  /// Strategi: hijau digeser ke arah olive/kuning — tritan masih
  /// bisa lihat komponen merah, jadi hijau yang "kekuningan" lebih
  /// menonjol dan tidak tertukar dengan biru.
  /// Baris 2: R0.5 G0.5 → hijau dapat tambahan merah (olive).
  static const List<double> tritan = <double>[
    1.0, 0.0, 0.0, 0, 0, //
    0.5, 0.5, 0.0, 0, 0, // hijau → dapat sedikit merah (olive)
    0.0, 0.0, 1.0, 0, 0, //
    0,   0,   0,   1, 0,
  ];

  /// Ambil matriks berdasarkan string tipe.
  static List<double>? forType(String type) {
    switch (type) {
      case 'protan':
        return protan;
      case 'deutan':
        return deutan;
      case 'tritan':
        return tritan;
      default:
        return null;
    }
  }

  /// Bangun ColorFilter siap pakai. Return null kalau tipe unknown.
  static ColorFilter? filterFor(String type) {
    final m = forType(type);
    if (m == null) return null;
    return ColorFilter.matrix(m);
  }
}