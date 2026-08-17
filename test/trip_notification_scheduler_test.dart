import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/database/database_helper.dart';
import 'package:rahhal_flutter/core/services/trip_notification_scheduler.dart';

class _MockDb extends Mock implements DatabaseHelper {}

void main() {
  group('TripNotificationScheduler.pickLocalizedName', () {
    final scheduler = TripNotificationScheduler(dbHelper: _MockDb());

    test('prefers the English name in English mode when one exists', () {
      expect(
        scheduler.pickLocalizedName('متحف بغداد', 'Baghdad Museum', 'en'),
        'Baghdad Museum',
      );
    });

    test('falls back to Arabic in English mode when no English name exists', () {
      expect(
        scheduler.pickLocalizedName('متحف بغداد', null, 'en'),
        'متحف بغداد',
      );
    });

    test('uses Arabic in Arabic mode even when an English name exists', () {
      expect(
        scheduler.pickLocalizedName('متحف بغداد', 'Baghdad Museum', 'ar'),
        'متحف بغداد',
      );
    });

    test('an empty or missing Arabic name with no usable English is null', () {
      expect(scheduler.pickLocalizedName(null, null, 'ar'), isNull);
      expect(scheduler.pickLocalizedName('  ', '', 'en'), isNull);
    });
  });
}
