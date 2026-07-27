import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/core/utils/opening_hours.dart';

void main() {
  // 2026-07-27 is a Monday.
  final monday = DateTime(2026, 7, 27);
  final tuesday = DateTime(2026, 7, 28);

  const hours =
      'Monday: 9:00 AM – 11:00 PM • Tuesday: 9:00 AM – 12:00 AM • '
      'Wednesday: Closed • Thursday: Open 24 hours';

  test('reads the closing time for the right weekday', () {
    expect(closingTimeFor(hours, monday), DateTime(2026, 7, 27, 23, 0));
  });

  test('past-midnight closing rolls to the next day', () {
    // Tuesday 9AM–12AM closes at 00:00 on Wednesday, not 00:00 Tuesday.
    expect(closingTimeFor(hours, tuesday), DateTime(2026, 7, 29, 0, 0));
  });

  test('closed and 24-hour days produce no warning', () {
    expect(closingTimeFor(hours, DateTime(2026, 7, 29)), isNull); // Wednesday
    expect(closingTimeFor(hours, DateTime(2026, 7, 30)), isNull); // Thursday
  });

  test('24-hour clock format works', () {
    expect(
      closingTimeFor('Monday: 09:00 – 23:30', monday),
      DateTime(2026, 7, 27, 23, 30),
    );
  });

  test('missing, empty or unparseable input yields null, never a guess', () {
    expect(closingTimeFor(null, monday), isNull);
    expect(closingTimeFor('', monday), isNull);
    expect(closingTimeFor('مفتوح يومياً', monday), isNull);
    // Only one time on the line — can't tell open from close.
    expect(closingTimeFor('Monday: 9:00 AM', monday), isNull);
    // Weekday absent from the text.
    expect(closingTimeFor('Friday: 9:00 AM – 5:00 PM', monday), isNull);
  });

  test('invalid clock values are rejected', () {
    expect(closingTimeFor('Monday: 9:00 AM – 13:00 PM', monday), isNull);
    expect(closingTimeFor('Monday: 9:00 AM – 11:75 PM', monday), isNull);
  });

  test('noon and midnight edge cases', () {
    expect(
      closingTimeFor('Monday: 8:00 AM – 12:00 PM', monday),
      DateTime(2026, 7, 27, 12, 0), // noon, same day
    );
  });
}
