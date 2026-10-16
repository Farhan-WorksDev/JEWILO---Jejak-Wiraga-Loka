import 'package:flutter/material.dart';
import '../data/saman_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/screen_announcer.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final groups = _buildGroups(s);

    // Bangun summary panjang — dibacakan saat halaman dibuka.
    final summary = _buildSummary(groups);

    return ScreenAnnouncer(
      title: 'Notifikasi',
      summary: summary,
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          backgroundColor: C.bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: C.ink),
            onPressed: () {
              announceAction('Menutup halaman notifikasi, kembali ke halaman sebelumnya');
              Navigator.pop(context);
            },
          ),
          title: const Text('Notifikasi',
              style: TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
        ),
        body: groups.isEmpty
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 60, color: C.line),
                  SizedBox(height: 10),
                  Text('Belum ada notifikasi',
                      style: TextStyle(color: C.muted)),
                ]),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  for (final g in groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(g.label.toUpperCase(),
                          style: const TextStyle(
                              color: C.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ),
                    for (final it in g.items) ...[
                      _tile(it),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  /// Bangun teks lengkap untuk dibacakan saat halaman dibuka.
  String _buildSummary(List<_NotifGroup> groups) {
    if (groups.isEmpty) {
      return 'Belum ada notifikasi.';
    }

    final buf = StringBuffer();

    // Hitung total notifikasi
    final total = groups.fold<int>(0, (a, g) => a + g.items.length);
    buf.write('Ada $total notifikasi. ');

    // Bacakan per grup
    for (var gi = 0; gi < groups.length; gi++) {
      final group = groups[gi];
      buf.write('Kategori ${group.label}: ');

      for (var i = 0; i < group.items.length; i++) {
        final n = group.items[i];
        buf.write('Notifikasi ${i + 1}. ${n.title}. ${n.body}. ');
      }
    }

    return buf.toString().trim();
  }

  Widget _tile(_Notif n) => Semantics(
        button: false,
        label: '${n.title}. ${n.body}. Waktu ${n.time}',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: n.soft, shape: BoxShape.circle),
              child: Icon(n.icon, color: n.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(n.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                      Text(n.time,
                          style: const TextStyle(
                              color: C.muted, fontSize: 11)),
                    ]),
                    const SizedBox(height: 4),
                    Text(n.body,
                        style: const TextStyle(
                            color: C.muted, fontSize: 12.5, height: 1.4)),
                  ]),
            ),
          ]),
        ),
      );

  List<_NotifGroup> _buildGroups(AppState s) {
    final today = <_Notif>[];
    final yesterday = <_Notif>[];

    if (!s.practicedToday) {
      today.add(_Notif(
        title: 'Waktunya latihan hari ini',
        body:
            'Pengingat harian pukul ${s.reminderLabel}. Yuk lanjut latihan!',
        time: s.reminderLabel,
        icon: Icons.alarm,
        color: C.orange,
        soft: C.orangeSoft,
      ));
    } else {
      today.add(_Notif(
        title: 'Latihan hari ini sudah beres',
        body: 'Streak ${s.currentStreak} hari aman. Besok lanjut lagi ya!',
        time: 'Hari ini',
        icon: Icons.check_circle,
        color: C.green,
        soft: C.greenSoft,
      ));
    }

    if (s.currentStreak > 0) {
      today.add(_Notif(
        title: 'Streak ${s.currentStreak} hari',
        body: 'Konsisten itu kunci. Jangan sampai terlewat!',
        time: 'Hari ini',
        icon: Icons.local_fire_department,
        color: C.red,
        soft: C.redSoft,
      ));
    }

    for (final b in s.badges) {
      today.add(_Notif(
        title: 'Lencana: ${badgeNames[b] ?? b}',
        body: 'Kamu membuka pencapaian baru.',
        time: 'Hari ini',
        icon: Icons.workspace_premium,
        color: C.green,
        soft: C.greenSoft,
      ));
    }

    if (s.totalSeconds > 0) {
      yesterday.add(_Notif(
        title: 'Total latihan kamu ${fmtDur(s.totalSeconds)}',
        body:
            'Akumulasi semua sesi. Semakin sering latihan, semakin cepat kuasai!',
        time: 'Kemarin',
        icon: Icons.insights,
        color: C.purple,
        soft: C.purpleSoft,
      ));
    }

    if (!s.allDone) {
      final next = s.completed.length;
      yesterday.add(_Notif(
        title: 'Lanjut Variasi ${Level.values[next].label}',
        body:
            'Kamu sudah menyelesaikan ${s.completed.length} dari 3 variasi.',
        time: 'Info',
        icon: Icons.play_circle,
        color: C.purple,
        soft: C.purpleSoft,
      ));
    }

    final groups = <_NotifGroup>[];
    if (today.isNotEmpty) groups.add(_NotifGroup('Hari Ini', today));
    if (yesterday.isNotEmpty) {
      groups.add(_NotifGroup('Kemarin & Sebelumnya', yesterday));
    }
    return groups;
  }
}

class _NotifGroup {
  final String label;
  final List<_Notif> items;
  _NotifGroup(this.label, this.items);
}

class _Notif {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final Color soft;
  _Notif({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    required this.soft,
  });
}