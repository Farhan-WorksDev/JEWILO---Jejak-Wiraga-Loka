import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Pengingat harian lokal, 100% offline.
/// Pake zonedSchedule biar jam spesifik (bukan "24 jam dari sekarang").
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Init timezone database
    tzdata.initializeTimeZones();
    final offset = DateTime.now().timeZoneOffset.inHours;
    final tzName = offset == 9
        ? 'Asia/Jayapura'
        : offset == 8
            ? 'Asia/Makassar'
            : 'Asia/Jakarta';
    tz.setLocalLocation(tz.getLocation(tzName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Minta izin notif (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Jadwal notif harian di jam & menit spesifik.
  Future<void> scheduleDaily(int hour, int minute) async {
    await init();
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        1001,
        'Waktunya latihan Tari Saman',
        'Yuk buka Belajar Bareng, cukup 2 menit!',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Pengingat Harian',
            channelDescription: 'Pengingat latihan harian (offline)',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Reminder scheduled at $scheduled');
    } catch (e) {
      debugPrint('zonedSchedule error: $e, fallback to periodicallyShow');
      await _plugin.periodicallyShow(
        1001,
        'Waktunya latihan Tari Saman',
        'Yuk buka Belajar Bareng, cukup 2 menit!',
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Pengingat Harian',
            channelDescription: 'Pengingat latihan harian (offline)',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}