import 'package:flutter/foundation.dart';
import '../constants/app_strings.dart';
import '../database/database_helper.dart';
import '../utils/opening_hours.dart';
import 'notification_preferences.dart';
import 'notification_service.dart';

/// Schedules the contextual reminders for one trip: a morning plan for each
/// day, a nudge to book that day's restaurant, and a "closes soon" warning.
///
/// Reads straight from SQLite so it works for trips created before this feature
/// existed, and takes already-localized strings because [NotificationService]
/// has no BuildContext.
///
/// Notification ids are derived from (trip, day), so running this again simply
/// replaces the previous schedule instead of stacking duplicates.
class TripNotificationScheduler {
  final DatabaseHelper _dbHelper;

  TripNotificationScheduler({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> scheduleForTrip({
    required String tripId,
    required AppStrings strings,
  }) async {
    try {
      // The user's switches in Settings gate each category. Checked once here
      // rather than per-day so a disabled category costs nothing.
      final dayPlansAllowed =
          await NotificationPreferences.isEnabled(NotificationPreferences.tripReminders);
      final suggestionsAllowed =
          await NotificationPreferences.isEnabled(NotificationPreferences.aiSuggestions);
      if (!dayPlansAllowed && !suggestionsAllowed) return;

      final days = await _dbHelper.query(
        'days',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'day_number ASC',
      );
      if (days.isEmpty) return;

      for (final day in days) {
        final dateText = day['date'] as String?;
        if (dateText == null) continue; // undated trip — nothing to anchor to
        final date = DateTime.tryParse(dateText);
        // Past days can't be reminded about.
        if (date == null || date.isBefore(_startOfToday())) continue;

        final dayNumber = (day['day_number'] as int?) ?? 0;
        final dayId = day['id'] as String;

        if (dayPlansAllowed) {
          await _scheduleDayPlan(tripId, dayId, dayNumber, date, strings);
        }
        if (suggestionsAllowed) {
          await _scheduleRestaurant(tripId, dayId, dayNumber, date, strings);
        }
      }
    } catch (e) {
      // Reminders are a convenience — never let them break opening a trip.
      debugPrint('[TripNotifications] scheduling failed: $e');
    }
  }

  static DateTime _startOfToday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _scheduleDayPlan(String tripId, String dayId, int dayNumber,
      DateTime date, AppStrings strings) async {
    final stops = await _dbHelper.query(
      'stops',
      where: 'day_id = ?',
      whereArgs: [dayId],
      orderBy: 'order_index ASC',
    );
    if (stops.isEmpty) return;

    final firstName = (stops.first['name'] as String?)?.trim();
    if (firstName == null || firstName.isEmpty) return;

    await NotificationService.scheduleDayPlan(
      tripId: tripId,
      dayNumber: dayNumber,
      title: strings.notifyDayPlanTitle(dayNumber),
      body: strings.notifyDayPlanBody(firstName, stops.length - 1),
      dayDate: date,
    );
  }

  Future<void> _scheduleRestaurant(String tripId, String dayId, int dayNumber,
      DateTime date, AppStrings strings) async {
    final rows = await _dbHelper.query(
      'restaurants',
      where: 'day_id = ?',
      whereArgs: [dayId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final r = rows.first;
    final name = (r['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return;

    await NotificationService.scheduleBookingReminder(
      tripId: tripId,
      dayNumber: dayNumber,
      title: strings.notifyBookingTitle,
      body: strings.notifyBookingBody(name),
      dayDate: date,
    );

    // "Closes in an hour" — only when the hours parse unambiguously, so a venue
    // with odd or missing hours produces no notification rather than a wrong one.
    final closing = closingTimeFor(r['opening_hours_en'] as String?, date);
    if (closing != null) {
      await NotificationService.scheduleClosingWarning(
        key: '${tripId}_${dayNumber}_${r['id']}',
        title: strings.notifyClosingTitle,
        body: strings.notifyClosingBody(name),
        closingTime: closing,
      );
    }
  }
}
