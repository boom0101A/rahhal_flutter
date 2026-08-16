import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/core/network/ai_service.dart';

void main() {
  group('StopResponse.fromJson opening_hours_en', () {
    test('reads the field when present', () {
      final stop = StopResponse.fromJson({
        'name': 'متحف بغداد',
        'name_en': 'Baghdad Museum',
        'opening_hours_en':
            'Monday: 9:00 AM – 5:00 PM • Tuesday: 9:00 AM – 5:00 PM',
      });

      expect(stop.openingHoursEn,
          'Monday: 9:00 AM – 5:00 PM • Tuesday: 9:00 AM – 5:00 PM');
    });

    test('is null when absent, same as an unverified stop', () {
      final stop = StopResponse.fromJson({
        'name': 'متحف بغداد',
        'name_en': 'Baghdad Museum',
      });

      expect(stop.openingHoursEn, isNull);
    });
  });
}
