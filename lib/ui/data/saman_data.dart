// Semua data Tari Saman ada di sini (hardcode = 100% offline).

enum Level { pemula, menengah, akhir }

extension LevelX on Level {
  String get label => const ['Pemula', 'Menengah', 'Mahir'][index];
  int get xp => const [50, 75, 100][index];
}

class Move {
  final String stage;
  final String name;
  final double durationSec;
  final double secPerBeat;
  final double pauseAfterSec;
  final String pose;
  final bool inserted;

  const Move({
    required this.stage,
    required this.name,
    required this.durationSec,
    required this.secPerBeat,
    required this.pauseAfterSec,
    required this.pose,
    this.inserted = false,
  });

  String get tempoLabel {
    final t = secPerBeat >= 2.5
        ? 'Santai'
        : secPerBeat >= 1.0
            ? 'Sedang'
            : secPerBeat >= 0.6
                ? 'Mulai Cepat'
                : 'Cepat';
    return '$t (~${secPerBeat.toStringAsFixed(1)} dtk/gerak)';
  }
}

class Variation {
  final Level level;
  final String focus;
  final List<Move> moves;
  const Variation(this.level, this.focus, this.moves);

  double get moveSec => moves.fold(0.0, (s, m) => s + m.durationSec);
  double get pauseSec =>
      moves.take(moves.length - 1).fold(0.0, (s, m) => s + m.pauseAfterSec);
  double get totalSec => moveSec + pauseSec;
  int get insertedCount => moves.where((m) => m.inserted).length;
}

const _pembuka = Move(
  stage: 'PEMBUKA',
  name: 'Salam Pembuka (Bersimpuh Sempurna)',
  durationSec: 4.0,
  secPerBeat: 4.0,
  pauseAfterSec: 1.5,
  pose: 'Menjaga postur tegak dan pandangan fokus ke depan.',
);
const _tepukPaha = Move(
  stage: 'SINKRONISASI',
  name: 'Tepuk Paha Kanan-Kiri Bergantian',
  durationSec: 2.5,
  secPerBeat: 1.2,
  pauseAfterSec: 1.0,
  pose: 'Menggunakan telapak tangan terbuka, ayunan stabil setinggi lutut.',
);
const _tepukDada = Move(
  stage: 'DINAMIKA SILANG',
  name: 'Tepuk Dada Silang (Dada Kiri & Kanan)',
  durationSec: 1.5,
  secPerBeat: 0.7,
  pauseAfterSec: 0.8,
  pose: 'Siku sejajar bahu, pergelangan tangan rileks dan terkunci ritme.',
);
const _klimaks = Move(
  stage: 'KLIMAKS',
  name: 'Sinkronisasi Tepuk Beruntun',
  durationSec: 1.0,
  secPerBeat: 0.5,
  pauseAfterSec: 0.0,
  pose: 'Wajib diselesaikan utuh dari awal sampai akhir tanpa berhenti.',
);

const _selipDadaGanda = Move(
  stage: 'SELIPAN',
  name: 'Tepuk Dada Ganda',
  durationSec: 2.0,
  secPerBeat: 0.9,
  pauseAfterSec: 0.6,
  pose: 'Dua tepukan dada cepat, bahu tetap turun dan punggung tegak.',
  inserted: true,
);
const _selipGoyang = Move(
  stage: 'SELIPAN',
  name: 'Goyang Badan Kiri-Kanan',
  durationSec: 2.0,
  secPerBeat: 0.8,
  pauseAfterSec: 0.5,
  pose: 'Badan condong bergantian, tumpuan tetap di lutut.',
  inserted: true,
);
const _selipSembah = Move(
  stage: 'SELIPAN',
  name: 'Sembah Menunduk Cepat',
  durationSec: 1.2,
  secPerBeat: 0.6,
  pauseAfterSec: 0.4,
  pose: 'Tangan merapat di dada, menunduk singkat lalu kembali tegak.',
  inserted: true,
);

Move _scale(Move m, double f) => Move(
      stage: m.stage,
      name: m.name,
      durationSec: double.parse((m.durationSec * f).toStringAsFixed(1)),
      secPerBeat: double.parse((m.secPerBeat * f).toStringAsFixed(1)),
      pauseAfterSec: double.parse((m.pauseAfterSec * f).toStringAsFixed(1)),
      pose: m.pose,
      inserted: m.inserted,
    );

List<Move> _s(List<Move> l, double f) => l.map((m) => _scale(m, f)).toList();

final List<Variation> samanVariations = [
  Variation(
    Level.pemula,
    'Melatih kelenturan telapak tangan dan ritme awal tanpa terburu-buru. Pastikan punggung tetap tegak.',
    [_pembuka, _tepukPaha, _tepukDada, _klimaks],
  ),
  Variation(
    Level.menengah,
    'Gerakan dasar yang sama, tapi tempo naik dan ada gerakan selipan di tengah rangkaian.',
    _s([_pembuka, _tepukPaha, _selipDadaGanda, _tepukDada, _selipGoyang, _klimaks], 0.8),
  ),
  Variation(
    Level.akhir,
    'Tempo cepat penuh dengan tiga gerakan selipan. Fokus pada kekompakan dan kestabilan sampai pose akhir.',
    _s([
      _pembuka,
      _selipSembah,
      _tepukPaha,
      _selipDadaGanda,
      _tepukDada,
      _selipGoyang,
      _klimaks
    ], 0.65),
  ),
];

const habitLaws = [
  ('Buat Jelas', 'Pemicu harian: kapan & di mana kamu latihan.'),
  ('Buat Menarik', 'XP, lencana, dan api streak sebagai hadiah.'),
  ('Buat Mudah', 'Mode 2 Menit: mulai kecil, tanpa alasan menunda.'),
  ('Buat Memuaskan', 'Centang harian & perayaan tiap variasi selesai.'),
];

const badgeNames = {
  'first_step': 'Langkah Pertama',
  'streak3': 'Streak 3 Hari',
  'streak7': 'Streak 7 Hari',
  'var_pemula': 'Lulus Pemula',
  'var_menengah': 'Lulus Menengah',
  'var_akhir': 'Lulus Akhir',
  'saman_complete': 'Penari Saman',
};
