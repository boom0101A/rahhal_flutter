import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rahhal_flutter/core/services/notification_service.dart';
import 'package:rahhal_flutter/core/services/notification_preferences.dart';

/// Regression test for "turning off one notification category cancelled
/// every scheduled notification in the app, including ones scheduled once at
/// creation time that are never rebuilt."
///
/// `NotificationService`'s `_scheduleAt` catches its own platform-channel
/// errors and never rethrows, so calling the real `scheduleTripReminder` /
/// `scheduleDocumentExpiryReminder` / etc. here safely "fails" against the
/// unregistered plugin in a test environment while still running the
/// (real, production) per-category id tracking that wraps it — exactly the
/// part this test needs to prove.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('disabling one category cancels only that category\'s tracked ids',
      () async {
    // Two reminders that are scheduled once and never rebuilt (the exact
    // gap the bug exploited) ...
    await NotificationService.scheduleTripReminder(
      tripId: 't1',
      title: 'x',
      body: 'x',
      tripStartDate: DateTime.now().add(const Duration(days: 10)),
    );
    await NotificationService.scheduleDocumentExpiryReminder(
      documentId: 'd1',
      title: 'x',
      body: 'x',
      expiryDate: DateTime.now().add(const Duration(days: 60)),
    );
    // ... and two under the OTHER category.
    await NotificationService.scheduleBookingReminder(
      tripId: 't1',
      dayNumber: 1,
      title: 'x',
      body: 'x',
      dayDate: DateTime.now().add(const Duration(days: 1)),
    );
    await NotificationService.scheduleClosingWarning(
      key: 'k1',
      title: 'x',
      body: 'x',
      closingTime: DateTime.now().add(const Duration(hours: 2)),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('notif_ids_notifications_trip_reminders'),
        hasLength(2), reason: 'trip-start + doc-expiry both tracked');
    expect(prefs.getStringList('notif_ids_notifications_ai_suggestions'),
        hasLength(2), reason: 'booking + closing both tracked');

    // Turn OFF only "AI suggestions" — the bug's exact trigger.
    await NotificationPreferences.setEnabled(
        NotificationPreferences.aiSuggestions, false);

    expect(
      prefs.getStringList('notif_ids_notifications_ai_suggestions') ?? const [],
      isEmpty,
      reason: 'the disabled category\'s ids were cancelled and forgotten '
          '(cancelCategory removes the key entirely, so this reads back as '
          'null, not an empty list — both mean "nothing tracked")',
    );
    expect(
      prefs.getStringList('notif_ids_notifications_trip_reminders'),
      hasLength(2),
      reason: 'trip-start and doc-expiry must survive untouched — this is '
          'exactly what cancelAll() used to destroy',
    );
  });

  test('disabling trip reminders does not touch AI suggestions', () async {
    await NotificationService.scheduleTripReminder(
      tripId: 't1',
      title: 'x',
      body: 'x',
      tripStartDate: DateTime.now().add(const Duration(days: 10)),
    );
    await NotificationService.scheduleBookingReminder(
      tripId: 't1',
      dayNumber: 1,
      title: 'x',
      body: 'x',
      dayDate: DateTime.now().add(const Duration(days: 1)),
    );

    await NotificationPreferences.setEnabled(
        NotificationPreferences.tripReminders, false);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('notif_ids_notifications_trip_reminders') ?? const [], isEmpty);
    expect(prefs.getStringList('notif_ids_notifications_ai_suggestions'), hasLength(1));
  });

  test('scheduling the same id twice is not tracked twice', () async {
    // Re-opening a trip re-schedules the same day-plan id (stable ids are
    // the documented mechanism for "replace, don't duplicate").
    for (var i = 0; i < 3; i++) {
      await NotificationService.scheduleDayPlan(
        tripId: 't1',
        dayNumber: 1,
        title: 'x',
        body: 'x',
        dayDate: DateTime.now().add(const Duration(days: 1)),
      );
    }
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('notif_ids_notifications_trip_reminders'), hasLength(1));
  });
}
