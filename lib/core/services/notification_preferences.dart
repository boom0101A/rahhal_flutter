import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// The user's notification choices, and the single place that decides whether a
/// given reminder is allowed to be scheduled.
///
/// These switches used to be written to SharedPreferences and read by nobody —
/// turning them off changed nothing. Every scheduling path now goes through
/// [isEnabled], so the toggles actually mean something.
class NotificationPreferences {
  /// Trip-start reminders, per-day plans and document-expiry warnings.
  static const tripReminders = 'notifications_trip_reminders';

  /// The assistant's contextual nudges: book today's restaurant, closing soon.
  static const aiSuggestions = 'notifications_ai_suggestions';

  static Future<bool> isEnabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // Default to on: a user who has never opened settings still wants the
    // reminders they implicitly signed up for by planning a trip.
    return prefs.getBool(key) ?? true;
  }

  static Future<void> setEnabled(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    // Turning a category off must also retract what's already queued —
    // otherwise reminders scheduled earlier keep firing for days.
    if (!value) await _cancelScheduled(key);
  }

  /// flutter_local_notifications can't cancel by category, so anything already
  /// queued for the disabled group is dropped and the still-enabled groups are
  /// rebuilt the next time a trip is opened (ids are stable, so nothing
  /// duplicates).
  static Future<void> _cancelScheduled(String key) async {
    await NotificationService.cancelAll();
  }
}
