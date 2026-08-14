import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'crash_reporter.dart';

/// Local (device) notifications: trip-start reminders and travel-document
/// expiry warnings. All scheduling goes through [_scheduleAt] so callers only
/// supply already-localized title/body text (the service has no BuildContext).
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'trip_reminders';

  /// The two toggleable groups in Settings. Defined here (not in
  /// NotificationPreferences) because this is the file that actually knows
  /// which schedule method belongs to which group — NotificationPreferences
  /// just reads these back as SharedPreferences keys.
  static const categoryTripReminders = 'notifications_trip_reminders';
  static const categoryAiSuggestions = 'notifications_ai_suggestions';
  static const categoryPush = 'notifications_push';

  /// flutter_local_notifications has no concept of categories — only
  /// individual numeric ids or cancel-everything. So each schedule call also
  /// records its id under its category here, and turning a category off
  /// cancels exactly those ids instead of every pending notification in the
  /// app. Without this, disabling "AI suggestions" alone silently cancelled a
  /// trip-start reminder and a passport-expiry warning too — both scheduled
  /// once at creation time and never rebuilt, so they were simply gone.
  static Future<void> _trackId(String category, int id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notif_ids_$category';
    final ids = prefs.getStringList(key) ?? <String>[];
    final idStr = id.toString();
    if (!ids.contains(idStr)) {
      await prefs.setStringList(key, [...ids, idStr]);
    }
  }

  /// Cancels every notification tracked under [category] and forgets them —
  /// the counterpart to [_trackId]. Call sites that rebuild on trip-open
  /// (day plan, booking, closing) will simply re-track fresh ids next time;
  /// the ones that don't (trip-start, document-expiry) stay cancelled until
  /// the user re-enables the category and reopens the relevant screen.
  static Future<void> cancelCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notif_ids_$category';
    final ids = prefs.getStringList(key) ?? <String>[];
    for (final idStr in ids) {
      final id = int.tryParse(idStr);
      if (id != null) await _cancel(id);
    }
    await prefs.remove(key);
  }

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
    } catch (e, st) {
      debugPrint('NotificationService initialize error: $e');
      reportNonFatal(e, st, reason: 'NotificationService.initialize failed');
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

  /// Reads the OS permission state WITHOUT prompting — for showing the user
  /// whether a reminder they've toggled "on" will actually fire. Both
  /// scheduling call sites request permission but never checked the result,
  /// so denying the OS prompt once left every reminder toggle showing "on"
  /// while nothing was ever actually scheduled, with no way to discover why.
  static Future<bool> hasPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final perms = await ios.checkPermissions();
        return perms?.isEnabled ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService hasPermission error: $e');
      // Unknown, not denied — don't scare the user over a platform quirk.
      return true;
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
    final id = _idFor('trip_$tripId');
    await _scheduleAt(
      id: id,
      title: title,
      body: body,
      when: tripStartDate.subtract(Duration(days: daysBefore)),
    );
    await _trackId(categoryTripReminders, id);
  }

  /// Warns before a travel document (passport/visa) expires.
  static Future<void> scheduleDocumentExpiryReminder({
    required String documentId,
    required String title,
    required String body,
    required DateTime expiryDate,
    int daysBefore = 30,
  }) async {
    final id = _idFor('doc_$documentId');
    await _scheduleAt(
      id: id,
      title: title,
      body: body,
      when: expiryDate.subtract(Duration(days: daysBefore)),
    );
    await _trackId(categoryTripReminders, id);
  }

  /// Morning briefing on each day of the trip: what today's plan is.
  /// [dayNumber] keeps the id stable so re-opening a trip replaces rather than
  /// duplicates the reminder.
  static Future<void> scheduleDayPlan({
    required String tripId,
    required int dayNumber,
    required String title,
    required String body,
    required DateTime dayDate,
    int hour = 8,
  }) async {
    final id = _idFor('day_${tripId}_$dayNumber');
    await _scheduleAt(
      id: id,
      title: title,
      body: body,
      when: DateTime(dayDate.year, dayDate.month, dayDate.day, hour),
    );
    await _trackId(categoryTripReminders, id);
  }

  /// Nudge to reserve the day's recommended restaurant, a few hours ahead of
  /// the meal rather than when the user is already standing at the door.
  static Future<void> scheduleBookingReminder({
    required String tripId,
    required int dayNumber,
    required String title,
    required String body,
    required DateTime dayDate,
    int hour = 10,
  }) async {
    final id = _idFor('book_${tripId}_$dayNumber');
    await _scheduleAt(
      id: id,
      title: title,
      body: body,
      when: DateTime(dayDate.year, dayDate.month, dayDate.day, hour),
    );
    await _trackId(categoryAiSuggestions, id);
  }

  /// "Closes in an hour" warning for a place the plan visits that day.
  /// [closingTime] must already be a real local DateTime — callers only pass
  /// one when the venue's hours parsed unambiguously, so an unparsed or odd
  /// format simply produces no notification instead of a wrong one.
  static Future<void> scheduleClosingWarning({
    required String key,
    required String title,
    required String body,
    required DateTime closingTime,
    Duration before = const Duration(hours: 1),
  }) async {
    final id = _idFor('close_$key');
    await _scheduleAt(
      id: id,
      title: title,
      body: body,
      when: closingTime.subtract(before),
    );
    await _trackId(categoryAiSuggestions, id);
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

  /// Shows a notification right now, via the same channel/details as every
  /// scheduled one — used by FcmService to display a push received while the
  /// app is in the foreground (Android only shows FCM's own tray notification
  /// automatically in the background/terminated, not while foregrounded).
  static Future<void> showImmediate({
    required String title,
    required String body,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
      await _plugin.show(id, title, body, _details);
    } catch (e) {
      debugPrint('NotificationService showImmediate error: $e');
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
