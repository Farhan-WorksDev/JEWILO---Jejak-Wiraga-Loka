import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/screen_announcer.dart';

class MuridDetailScreen extends StatefulWidget {
  final Map<String, dynamic> murid;
  const MuridDetailScreen({super.key, required this.murid});

  @override
  State<MuridDetailScreen> createState() => _MuridDetailScreenState();
}

class _MuridDetailScreenState extends State<MuridDetailScreen> {
  bool _kicking = false;

  String get _uid => (widget.murid['uid'] ?? '').toString();
  String get _nama => (widget.murid['nama'] ?? 'Siswa').toString();
  String get _email => (widget.murid['email'] ?? '-').toString();
  String get _photoUrl => (widget.murid['photoUrl'] ?? '').toString();
  int get _xp => (widget.murid['xp'] ?? 0) as int;
  int get _level => (_xp ~/ 100) + 1;
  int get _streak => (widget.murid['streak'] ?? 0) as int;
  int get _longest => (widget.murid['longest'] ?? 0) as int;
  int get _totalMinutes => (widget.murid['totalMinutes'] ?? 0) as int;
  int get _completedCount => (widget.murid['completedCount'] ?? 0) as int;
  String? get _lastDay => widget.murid['lastDay'] as String?;

  List<String> get _badges {
    final b = widget.murid['badges'];
    if (b is List) return b.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, int> get _secondsByDay {
    final m = widget.murid['secondsByDay'];
    if (m is Map) {
      return m.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return {};
  }

  Future<void> _kick() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluarkan murid?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            '"$_nama" akan dikeluarkan dari sanggar. Progres tetap tersimpan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluarkan')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _kicking = true);
    final res = await AuthService.instance.kickMurid(_uid);
    if (!mounted) return;
    setState(() => _kicking = false);
    if (res) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $_nama dikeluarkan')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Gagal mengeluarkan murid')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenAnnouncer(
      title: 'Detail Murid',
      summary: 'Progress $_nama. '
          'XP $_xp, level $_level, streak $_streak hari, '
          'total latihan ${_formatMenit(_totalMinutes)}, '
          '$_completedCount variasi selesai.',
      child: Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Text('Detail Murid',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                if (_uid.isNotEmpty)
                  IconButton(
                    tooltip: 'Keluarkan dari sanggar',
                    onPressed: _kicking ? null : _kick,
                    icon: Icon(
                      Icons.person_remove_outlined,
                      color: _kicking ? C.muted : C.red,
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _statGrid(),
                  const SizedBox(height: 20),
                  _sectionRiwayat(),
                  const SizedBox(height: 20),
                  _sectionBadges(),
                  const SizedBox(height: 20),
                  _infoTerakhir(),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [C.purpleDark, C.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white24,
              backgroundImage: _photoUrl.isNotEmpty
                  ? NetworkImage(_photoUrl)
                  : null,
              child: _photoUrl.isEmpty
                  ? Text(
                      _nama.isNotEmpty ? _nama[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(_nama,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_email,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: .8),
                    fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Level $_level',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

  Widget _statGrid() => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 110,
        children: [
          _statCard(Icons.bolt, '$_xp', 'Total XP', C.purple),
          _statCard(Icons.local_fire_department, '$_streak hari',
              'Streak Sekarang', Colors.orange),
          _statCard(Icons.emoji_events_outlined, '$_longest hari',
              'Streak Terpanjang', Colors.amber),
          _statCard(Icons.timer_outlined, _formatMenit(_totalMinutes),
              'Total Latihan', Colors.teal),
          _statCard(Icons.menu_book, '$_completedCount', 'Variasi Selesai',
              Colors.indigo),
          _statCard(Icons.badge_outlined, '${_badges.length}',
              'Badge Diperoleh', Colors.pink),
        ],
      );

  Widget _statCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17,
                      height: 1.1,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11, color: C.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionRiwayat() {
    final days = _last7Days();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.show_chart, color: C.purple, size: 18),
            SizedBox(width: 8),
            Text('Riwayat 7 Hari',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((d) {
              final sec = _secondsByDay[d.key] ?? 0;
              final menit = (sec / 60).round();
              const maxMenit = 60.0;
              final h = (menit / maxMenit).clamp(0.05, 1.0);
              return Column(
                children: [
                  Text('$menit',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: C.muted)),
                  const SizedBox(height: 4),
                  Container(
                    width: 26,
                    height: 60 * h,
                    decoration: BoxDecoration(
                      color: menit > 0 ? C.purple : C.line,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(d.label,
                      style: const TextStyle(
                          fontSize: 10, color: C.muted)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Text('(menit latihan per hari)',
              style: TextStyle(fontSize: 10, color: C.muted)),
        ],
      ),
    );
  }

  List<({String key, String label})> _last7Days() {
    final now = DateTime.now();
    const names = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    final out = <({String key, String label})>[];
    for (var i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      out.add((key: key, label: names[d.weekday % 7]));
    }
    return out;
  }

  Widget _sectionBadges() {
    final badges = _badges;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.military_tech, color: C.purple, size: 18),
            SizedBox(width: 8),
            Text('Badge',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          if (badges.isEmpty)
            const Text('Belum ada badge',
                style: TextStyle(color: C.muted, fontSize: 12.5))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((b) {
                final info = _badgeInfo(b);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: info.color.withValues(alpha: .3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(info.icon, size: 14, color: info.color),
                    const SizedBox(width: 6),
                    Text(info.label,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: info.color)),
                  ]),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  ({String label, IconData icon, Color color}) _badgeInfo(String key) {
    switch (key) {
      case 'first_step':
        return (
          label: 'Langkah Pertama',
          icon: Icons.flag,
          color: Colors.green
        );
      case 'streak3':
        return (
          label: 'Streak 3 Hari',
          icon: Icons.local_fire_department,
          color: Colors.orange
        );
      case 'streak7':
        return (
          label: 'Streak 7 Hari',
          icon: Icons.local_fire_department,
          color: Colors.deepOrange
        );
      case 'var_pemula':
        return (
          label: 'Variasi Pemula',
          icon: Icons.school,
          color: C.purple
        );
      case 'var_menengah':
        return (
          label: 'Variasi Menengah',
          icon: Icons.school,
          color: Colors.indigo
        );
      case 'var_akhir':
        return (
          label: 'Variasi Mahir',
          icon: Icons.school,
          color: Colors.red
        );
      case 'saman_complete':
        return (
          label: 'Tari Saman Tamat',
          icon: Icons.emoji_events,
          color: Colors.amber
        );
      default:
        return (label: key, icon: Icons.badge, color: C.muted);
    }
  }

  Widget _infoTerakhir() {
    final d = _daysSince(_lastDay);
    final label = d == null
        ? 'Belum pernah latihan'
        : d == 0
            ? 'Latihan hari ini'
            : '$d hari yang lalu';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.purpleSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.schedule, size: 18, color: C.purple),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Terakhir latihan: $label',
              style: TextStyle(
                  fontSize: 12.5,
                  color: C.purple.withValues(alpha: .9),
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  static int? _daysSince(String? dayStr) {
    if (dayStr == null || dayStr.isEmpty) return null;
    try {
      final t = DateTime.now();
      final today = DateTime(t.year, t.month, t.day);
      final l = DateTime.parse(dayStr);
      return today.difference(DateTime(l.year, l.month, l.day)).inDays;
    } catch (_) {
      return null;
    }
  }

  static String _formatMenit(int m) {
    if (m <= 0) return '0 mnt';
    if (m < 60) return '$m mnt';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}j' : '${h}j ${r}m';
  }
}