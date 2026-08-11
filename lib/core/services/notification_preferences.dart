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
  static const tripReminders = NotificationService.categoryTripReminders;

  /// The assistant's contextual nudges: book today's restaurant, closing soon.
  static const aiSuggestions = NotificationService.categoryAiSuggestions;

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

  /// Cancels only what's tracked under this category — trip-start and
  /// document-expiry reminders (scheduled once, never rebuilt) now stay
  /// cancelled correctly instead of the whole app's notifications being
  /// wiped every time any single category is turned off. Ids for the
  /// still-enabled groups are untouched, and day-plan/booking/closing
  /// reminders re-track fresh ids the next time a trip is opened anyway.
  static Future<void> _cancelScheduled(String key) async {
    await NotificationService.cancelCategory(key);
  }
}
