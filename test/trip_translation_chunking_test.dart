import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/database/database_helper.dart';
import 'package:rahhal_flutter/core/network/trip_translation_service.dart';

/// Regression tests for "the trip never switches to English."
///
/// The whole trip used to travel as ONE /api/translate request, so a single
/// timeout, 500 or rate-limit wrote nothing at all — and the next attempt
/// repeated the identical request and failed identically. Anything past the
/// server's 24000-char cap was also silently dropped, and because hotels are
/// collected last, hotel blurbs were the first thing to vanish.
class _MockDb extends Mock implements DatabaseHelper {}

class _MockDio extends Mock implements Dio {}

void main() {
  group('chunkItems', () {
    List<({String k, String t})> items(int count, {int charsEach = 10}) => [
          for (var i = 0; i < count; i++)
            (k: 'day.theme|$i', t: 'x' * charsEach),
        ];

    test('a small list stays in a single chunk', () {
      final chunks = TripTranslationService.chunkItems(items(5));
      expect(chunks, hasLength(1));
      expect(chunks.first, hasLength(5));
    });

    test('splits on the item-count cap', () {
      final chunks =
          TripTranslationService.chunkItems(items(25), maxItems: 10);
      expect(chunks.map((c) => c.length), [10, 10, 5]);
    });

    test('splits on the character cap', () {
      // 6 items x 100 chars, budget 250 -> 2 per chunk.
      final chunks = TripTranslationService.chunkItems(
        items(6, charsEach: 100),
        maxChars: 250,
      );
      expect(chunks.map((c) => c.length), [2, 2, 2]);
    });

    test('no chunk exceeds either cap', () {
      final chunks = TripTranslationService.chunkItems(
        items(50, charsEach: 300),
        maxChars: 1000,
        maxItems: 8,
      );
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(8));
        // A chunk may exceed the char budget only when it holds one
        // oversized item (see below); with 300-char items it never should.
        final chars = chunk.fold<int>(0, (n, i) => n + i.t.length);
        expect(chars, lessThanOrEqualTo(1000));
      }
    });

    test('an item larger than the whole budget still gets its own chunk, never dropped',
        () {
      final oversized = [
        (k: 'a|1', t: 'x' * 50),
        (k: 'b|2', t: 'y' * 5000), // bigger than maxChars on its own
        (k: 'c|3', t: 'z' * 50),
      ];

      final chunks =
          TripTranslationService.chunkItems(oversized, maxChars: 1000);

      // Nothing may be silently lost — that was the original server-side bug.
      final allKeys =
          chunks.expand((c) => c).map((i) => i.k).toList();
      expect(allKeys, ['a|1', 'b|2', 'c|3']);
      expect(chunks.any((c) => c.length == 1 && c.first.k == 'b|2'), isTrue);
    });

    test('an empty list produces no chunks', () {
      expect(TripTranslationService.chunkItems(const []), isEmpty);
    });
  });

  group('ensureEnglish: one failing chunk must not discard the others', () {
    late _MockDb db;
    late _MockDio dio;
    late TripTranslationService service;

    setUp(() {
      db = _MockDb();
      dio = _MockDio();
      service = TripTranslationService(dbHelper: db, dio: dio);

      // No trip-level prose, so the only untranslated rows are the days below
      // — keeps the fixture focused on chunk behaviour.
      when(() => db.queryOne('trips',
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'))).thenAnswer((_) async => null);

      when(() => db.update(any(), any(),
              where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
          .thenAnswer((_) async => 1);
    });

    /// 5000 chars per theme, so two never fit together under the 8000-char
    /// budget — [count] days therefore means exactly [count] single-item
    /// chunks, which keeps the per-chunk assertions below unambiguous.
    void stubDays(int count) {
      when(() => db.query(any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'))).thenAnswer((invocation) async {
        final table = invocation.positionalArguments.first as String;
        if (table != 'days') return <Map<String, dynamic>>[];
        return [
          for (var i = 0; i < count; i++)
            {'id': 'd$i', 'theme': 'ث' * 5000, 'theme_en': null},
        ];
      });
    }

    test('the surviving chunks are still persisted', () async {
      stubDays(3);

      var call = 0;
      when(() => dio.post(any(),
          data: any(named: 'data'),
          options: any(named: 'options'))).thenAnswer((invocation) async {
        call++;
        final data = invocation.namedArguments[#data] as Map;
        final sent = (data['items'] as List).cast<Map>();
        // The middle chunk fails the way a real timeout/500 would.
        if (call == 2) throw DioException(requestOptions: RequestOptions());
        return Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
          data: {
            'items': [
              for (final item in sent) {'k': item['k'], 't': 'translated'},
            ],
          },
        );
      });

      final ok = await service.ensureEnglish('t1');

      // Partial success is still success — the old code returned false and
      // wrote nothing whenever any part failed.
      expect(ok, isTrue);
      expect(call, 3,
          reason: 'chunk 3 must still be sent after chunk 2 threw');
      // One update per surviving chunk (chunks are single-item here), so the
      // failure cost exactly its own row and nothing else.
      verify(() => db.update('days', any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'))).called(2);
    });

    test('a chunk that fails leaves its row untranslated for the next pass', () async {
      stubDays(1);

      when(() => dio.post(any(),
              data: any(named: 'data'), options: any(named: 'options')))
          .thenThrow(DioException(requestOptions: RequestOptions()));

      final ok = await service.ensureEnglish('t1');

      expect(ok, isFalse);
      // Nothing written, so _collectUntranslated will offer it again next time.
      verifyNever(() => db.update('days', any(),
          where: any(named: 'where'), whereArgs: any(named: 'whereArgs')));
    });
  });
}
