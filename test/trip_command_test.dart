import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/features/ai_chat/domain/trip_command.dart';

void main() {
  group('delete day', () {
    test('Arabic ordinals and digits', () {
      final a = parseTripCommand('احذف اليوم الثالث');
      expect(a?.kind, TripCommandKind.deleteDay);
      expect(a?.dayNumber, 3);

      expect(parseTripCommand('الغي اليوم 2')?.dayNumber, 2);
      // Arabic-Indic digits.
      expect(parseTripCommand('احذف اليوم ٤')?.dayNumber, 4);
    });

    test('English', () {
      final c = parseTripCommand('delete day 3');
      expect(c?.kind, TripCommandKind.deleteDay);
      expect(c?.dayNumber, 3);
    });

    test('a day with no number is refused, never guessed', () {
      expect(parseTripCommand('احذف اليوم'), isNull);
      expect(parseTripCommand('delete the day'), isNull);
    });
  });

  group('delete stop', () {
    test('captures the place name', () {
      final c = parseTripCommand('احذف متحف بغداد');
      expect(c?.kind, TripCommandKind.deleteStop);
      expect(c?.target, contains('متحف بغداد'));
    });

    test('English', () {
      final c = parseTripCommand('remove Baghdad Museum');
      expect(c?.kind, TripCommandKind.deleteStop);
      expect(c?.target, contains('baghdad museum'));
    });
  });

  group('mark visited', () {
    test('Arabic and English', () {
      expect(parseTripCommand('زرت متحف بغداد')?.kind,
          TripCommandKind.markVisited);
      expect(parseTripCommand('visited Erbil Citadel')?.kind,
          TripCommandKind.markVisited);
    });
  });

  group('ordinary questions are never commands', () {
    test('questions and chatter pass through untouched', () {
      expect(parseTripCommand('ما هي أفضل الأماكن في بغداد؟'), isNull);
      expect(parseTripCommand('كم تكلفة الرحلة؟'), isNull);
      expect(parseTripCommand('what should I eat in Erbil?'), isNull);
      expect(parseTripCommand('اقترح لي مطعم'), isNull);
      expect(parseTripCommand(''), isNull);
      expect(parseTripCommand('   '), isNull);
    });
  });
}
