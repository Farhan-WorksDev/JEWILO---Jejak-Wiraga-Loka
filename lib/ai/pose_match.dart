import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../ui/data/saman_data.dart';

/// 1 frame hasil ekstraksi (300 fitur). Pose = 33 landmark x (x, y, z, visibility).
class PoseFrame {
  final List<double> data;
  final int timestampMs;
  const PoseFrame(this.data, this.timestampMs);

  double x(int i) => data[i * 4];
  double y(int i) => data[i * 4 + 1];
  double vis(int i) => data[i * 4 + 3];
}

/// Index landmark pose MediaPipe yang dipakai.
class Lm {
  static const nose = 0;
  static const lSh = 11, rSh = 12;
  static const lEl = 13, rEl = 14;
  static const lWr = 15, rWr = 16;
  static const lHip = 23, rHip = 24;
}

/// 4 ruas lengan yang dinilai: [lengan atas kiri, lengan bawah kiri,
/// lengan atas kanan, lengan bawah kanan].
const List<List<int>> kBones = [
  [Lm.lSh, Lm.lEl],
  [Lm.lEl, Lm.lWr],
  [Lm.rSh, Lm.rEl],
  [Lm.rEl, Lm.rWr],
];
const List<String> kBoneNames = [
  'siku kiri',
  'tangan kiri',
  'siku kanan',
  'tangan kanan',
];

/// Satu pose acuan (keyframe).
///
/// Sudut diukur di RUANG LAYAR (yang dilihat user di kamera depan / cermin):
///   0° = ke kanan layar, 90° = ke bawah, 180° = ke kiri layar, -90° = ke atas.
/// "Kiri" = kiri badan user (muncul di kiri layar saat pakai kamera depan).
class PoseKeyframe {
  final String label;
  final List<double> angles; // 4 sudut ruas lengan
  final double? tilt; // kemiringan garis bahu (derajat), null = diabaikan
  final int holdMs; // berapa lama pose harus ditahan supaya dianggap kena
  const PoseKeyframe(this.label, this.angles, {this.tilt, this.holdMs = 400});
}

// ---------------------------------------------------------------------------
// POSE ACUAN. Angka di sini ditulis dari perkiraan, silakan kalibrasi:
// lakukan pose yang benar di depan kamera, TAHAN LAMA layar latihan, lalu
// salin angka yang tercetak di logcat ke sini.
// ---------------------------------------------------------------------------
const kfBersimpuh = PoseKeyframe('Tegak, tangan di paha', [
  99,
  73,
  81,
  107,
], holdMs: 1200);
const kfPahaKanan = PoseKeyframe('Tepuk paha kanan', [128, -61, 81, 107]);
const kfPahaKiri = PoseKeyframe('Tepuk paha kiri', [99, 73, 52, -119]);
const kfDadaKiri = PoseKeyframe('Tepuk dada kiri', [172, 12, 8, -70]);
const kfDadaKanan = PoseKeyframe('Tepuk dada kanan', [172, -110, 8, 168]);
const kfDadaRapat = PoseKeyframe('Dada rapat', [172, 12, 8, 168]);
const kfDadaBuka = PoseKeyframe('Tangan terbuka', [172, -110, 8, -70]);
const kfSembah = PoseKeyframe('Sembah di dada', [
  94,
  -39,
  86,
  -141,
], holdMs: 700);
const kfCondongKiri = PoseKeyframe('Condong kiri', [
  99,
  73,
  81,
  107,
], tilt: -10);
const kfCondongKanan = PoseKeyframe('Condong kanan', [
  99,
  73,
  81,
  107,
], tilt: 10);

/// Urutan pose yang harus dilakukan untuk tiap gerakan (dicocokkan lewat nama).
List<PoseKeyframe> keyframesFor(Move m) {
  switch (m.name) {
    case 'Salam Pembuka (Bersimpuh Sempurna)':
      return const [kfBersimpuh];
    case 'Tepuk Paha Kanan-Kiri Bergantian':
      return const [kfPahaKanan, kfPahaKiri];
    case 'Tepuk Dada Silang (Dada Kiri & Kanan)':
      return const [kfDadaKiri, kfDadaKanan];
    case 'Sinkronisasi Tepuk Beruntun':
      return const [kfPahaKanan, kfDadaKiri, kfPahaKiri, kfDadaKanan];
    case 'Tepuk Dada Ganda':
      return const [kfDadaRapat, kfDadaBuka, kfDadaRapat];
    case 'Goyang Badan Kiri-Kanan':
      return const [kfCondongKiri, kfCondongKanan];
    case 'Sembah Menunduk Cepat':
      return const [kfSembah];
    default:
      return const [kfBersimpuh];
  }
}

// ---------------------------------------------------------------------------
// Penilaian
// ---------------------------------------------------------------------------
const double kPassScore = 60; // kuning atau lebih = boleh lanjut
const double kGoodScore = 80; // hijau
const double _tolArm = 80; // toleransi derajat untuk skor 0
const double _tolTilt = 30;

class MatchResult {
  final double score; // 0..100
  final bool bodyVisible;
  final List<double?> segScore; // 4 ruas lengan
  final List<double?> segAngle;
  final double? tiltAngle;
  final double? tiltScore;
  final int worst; // index ruas terburuk, 4 = tilt, -1 = tidak ada
  final String? hint;
  const MatchResult({
    required this.score,
    required this.bodyVisible,
    required this.segScore,
    required this.segAngle,
    this.tiltAngle,
    this.tiltScore,
    this.worst = -1,
    this.hint,
  });
}

double angDiff(double a, double b) {
  var d = (a - b) % 360;
  if (d < 0) d += 360;
  return d > 180 ? 360 - d : d;
}

/// Sudut ruas (a -> b) di ruang layar, derajat.
double? liveSegAngle(
  PoseFrame f,
  int a,
  int b, {
  required bool mirror,
  required Size frame,
}) {
  if (!lmVisible(f, a) || !lmVisible(f, b)) return null;
  var vx = (f.x(b) - f.x(a)) * frame.width;
  final vy = (f.y(b) - f.y(a)) * frame.height;
  if (mirror) vx = -vx;
  return math.atan2(vy, vx) * 180 / math.pi;
}

/// Kemiringan garis bahu kiri -> kanan (derajat, -90..90).
double? liveTilt(PoseFrame f, {required bool mirror, required Size frame}) {
  if (!lmVisible(f, Lm.lSh) || !lmVisible(f, Lm.rSh)) return null;
  var vx = (f.x(Lm.rSh) - f.x(Lm.lSh)) * frame.width;
  final vy = (f.y(Lm.rSh) - f.y(Lm.lSh)) * frame.height;
  if (mirror) vx = -vx;
  var a = math.atan2(vy, vx) * 180 / math.pi;
  if (a > 90) a -= 180;
  if (a < -90) a += 180;
  return a;
}

bool _hasVis(PoseFrame f) {
  for (var i = 0; i < 33; i++) {
    if (f.vis(i) > 0.01) return true;
  }
  return false;
}

/// Landmark ada di dalam frame dan cukup terlihat.
bool lmVisible(PoseFrame f, int i) {
  final x = f.x(i), y = f.y(i);
  if (x <= 0 || x >= 1 || y <= 0 || y >= 1) return false;
  return _hasVis(f) ? f.vis(i) >= 0.35 : true;
}

MatchResult matchPose(
  PoseFrame f,
  PoseKeyframe t, {
  required bool mirror,
  required Size frame,
}) {
  final angles = <double?>[
    for (final b in kBones)
      liveSegAngle(f, b[0], b[1], mirror: mirror, frame: frame),
  ];
  final tilt = liveTilt(f, mirror: mirror, frame: frame);

  final visible = angles.every((a) => a != null);
  if (!visible) {
    return MatchResult(
      score: 0,
      bodyVisible: false,
      segScore: List<double?>.filled(4, null),
      segAngle: angles,
      tiltAngle: tilt,
      hint: 'Posisikan badan & kedua tangan di dalam layar',
    );
  }

  final scores = <double>[];
  for (var i = 0; i < 4; i++) {
    final d = angDiff(angles[i]!, t.angles[i]);
    scores.add((100 * (1 - d / _tolArm)).clamp(0, 100).toDouble());
  }
  double? tiltScore;
  if (t.tilt != null) {
    final d = ((tilt ?? 0) - t.tilt!).abs();
    tiltScore = (100 * (1 - d / _tolTilt)).clamp(0, 100).toDouble();
  }

  const w = [1.0, 1.3, 1.0, 1.3];
  var sum = 0.0, wsum = 0.0, minS = 100.0;
  var worst = 0;
  for (var i = 0; i < 4; i++) {
    sum += w[i] * scores[i];
    wsum += w[i];
    if (scores[i] < minS) {
      minS = scores[i];
      worst = i;
    }
  }
  if (tiltScore != null) {
    sum += tiltScore;
    wsum += 1;
    if (tiltScore < minS) {
      minS = tiltScore;
      worst = 4;
    }
  }
  final overall = 0.6 * (sum / wsum) + 0.4 * minS;

  String? hint;
  if (minS < kGoodScore) {
    hint = worst == 4
        ? 'Condongkan badan ke ${t.tilt! < 0 ? 'kiri' : 'kanan'}'
        : 'Sejajarkan ${kBoneNames[worst]}';
  }

  return MatchResult(
    score: overall,
    bodyVisible: true,
    segScore: scores,
    segAngle: angles,
    tiltAngle: tilt,
    tiltScore: tiltScore,
    worst: worst,
    hint: hint,
  );
}

// ---------------------------------------------------------------------------
// Geometri kerangka acuan (satuan: lebar bahu = 1, titik 0 = tengah bahu,
// sumbu y ke bawah). Urutan: lSh, rSh, lEl, rEl, lWr, rWr, lHip, rHip, kepala.
// ---------------------------------------------------------------------------
const double _upper = 0.75, _fore = 0.65;

List<Offset> templatePoints(PoseKeyframe t) {
  final tr = (t.tilt ?? 0) * math.pi / 180;
  final d = Offset(math.cos(tr), math.sin(tr)); // arah bahu kiri -> kanan
  final down = Offset(-math.sin(tr), math.cos(tr)); // arah badan ke bawah
  final lSh = d * -0.5;
  final rSh = d * 0.5;

  Offset dir(double deg) =>
      Offset(math.cos(deg * math.pi / 180), math.sin(deg * math.pi / 180));
  final lEl = lSh + dir(t.angles[0]) * _upper;
  final lWr = lEl + dir(t.angles[1]) * _fore;
  final rEl = rSh + dir(t.angles[2]) * _upper;
  final rWr = rEl + dir(t.angles[3]) * _fore;
  final hipMid = down * 1.35;
  final lHip = hipMid + d * -0.4;
  final rHip = hipMid + d * 0.4;
  final head = down * -0.6;
  return [lSh, rSh, lEl, rEl, lWr, rWr, lHip, rHip, head];
}
