import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  Future<void> scheduleTestNotification() async {
    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));

    await _notificationsPlugin.zonedSchedule(
      123456,
      'Tes Pengingat TaskBell',
      'Jika pesan ini muncul, penjadwalan notifikasi berfungsi.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Pengingat tugas dari TaskBell',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _notificationsPlugin.pendingNotificationRequests();
  }

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);

    final android = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Minta izin menampilkan notifikasi pada Android 13+.
    await android?.requestNotificationsPermission();

    // Minta izin alarm tepat waktu jika didukung versi plugin.
    await android?.requestExactAlarmsPermission();
  }

  Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      999999,
      'TaskBell Berhasil!',
      'Notifikasi pengingat berhasil ditampilkan.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Pengingat tugas dari TaskBell',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Pengingat tugas dari TaskBell',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
