import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  static Future<void> scheduleTripReminder({
    required int id,
    required String tripName,
    required DateTime tripDate,
  }) async {
    // Reminder 3 days before trip date
    final reminderDate = tripDate.subtract(const Duration(days: 3));
    if (reminderDate.isBefore(DateTime.now())) return;

    try {
      final scheduledTZDate = tz.TZDateTime.from(reminderDate, tz.local);
      await _plugin.zonedSchedule(
        id,
        '✈️ رحلتك إلى $tripName تقترب!',
        'بعد 3 أيام فقط — تأكد من استعداداتك',
        scheduledTZDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'trip_reminders',
            'تذكيرات الرحلات',
            channelDescription: 'تنبيهات بمواعيد الرحلات المجدولة القادمة',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService scheduleTripReminder error: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService cancelAll error: $e');
    }
  }
}
