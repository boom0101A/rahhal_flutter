import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local (device) notifications: trip-start reminders and travel-document
/// expiry warnings. All scheduling goes through [_scheduleAt] so callers only
/// supply already-localized title/body text (the service has no BuildContext).
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'trip_reminders';

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

  /// Ask for the OS notification permission. On Android 13+ this shows the
  /// system POST_NOTIFICATIONS dialog; on older Android it's a no-op that
  /// returns true. Safe to call more than once.
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
            alert: true, badge: true, sound: true);
        return granted ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
      return false;
    }
  }

  /// Notification IDs must be 32-bit ints; derive a stable positive one from
  /// any string key (trip id, document id) so re-scheduling replaces rather
  /// than duplicates.
  static int _idFor(String key) => key.hashCode & 0x7fffffff;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'تذكيرات الرحلات',
      channelDescription: 'تنبيهات بمواعيد الرحلات ووثائق السفر',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    // Never schedule in the past — the plugin would fire immediately.
    if (when.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService _scheduleAt error: $e');
    }
  }

  /// Reminds the traveller a few days before the trip starts.
  static Future<void> scheduleTripReminder({
    required String tripId,
    required String title,
    required String body,
    required DateTime tripStartDate,
    int daysBefore = 3,
  }) async {
    await _scheduleAt(
      id: _idFor('trip_$tripId'),
      title: title,
      body: body,
      when: tripStartDate.subtract(Duration(days: daysBefore)),
    );
  }

  /// Warns before a travel document (passport/visa) expires.
  static Future<void> scheduleDocumentExpiryReminder({
    required String documentId,
    required String title,
    required String body,
    required DateTime expiryDate,
    int daysBefore = 30,
  }) async {
    await _scheduleAt(
      id: _idFor('doc_$documentId'),
      title: title,
      body: body,
      when: expiryDate.subtract(Duration(days: daysBefore)),
    );
  }

  static Future<void> cancelTrip(String tripId) => _cancel(_idFor('trip_$tripId'));
  static Future<void> cancelDocument(String documentId) =>
      _cancel(_idFor('doc_$documentId'));

  static Future<void> _cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('NotificationService cancel error: $e');
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
