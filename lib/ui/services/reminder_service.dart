import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Pengingat harian lokal, 100% offline.
/// Hanya dipakai kalau user aktifkan "Pengingat Latihan" di Pengaturan.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> scheduleDaily(int hour, int minute) async {
    await init();
    await _plugin.cancelAll();
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
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
