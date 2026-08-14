import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/database/database_helper.dart';
import 'package:rahhal_flutter/core/network/cloud_sync_service.dart';
import 'package:rahhal_flutter/features/ai_chat/data/trip_command_executor.dart';
import 'package:rahhal_flutter/features/ai_chat/domain/trip_command.dart';

/// Regression test for a risky `command.target!` non-null assertion in
/// `_previewStop` — a null target could only reach it via a future change
/// to TripCommand construction, not via parseTripCommand today, but the
/// assertion itself had no explicit guard. Proves the fixed guard degrades
/// gracefully (problem: 'error') instead of throwing, and that normal
/// (non-null-target) behavior is unchanged.
class _MockDb extends Mock implements DatabaseHelper {}

class _MockSync extends Mock implements CloudSyncService {}

void main() {
  late _MockDb db;
  late TripCommandExecutor executor;

  setUp(() {
    db = _MockDb();
    executor = TripCommandExecutor(dbHelper: db, syncService: _MockSync());
  });

  group('null target', () {
    test('deleteStop with a null target returns problem=error, does not throw', () async {
      const command = TripCommand(kind: TripCommandKind.deleteStop, target: null);

      final preview = await executor.preview(tripId: 't1', command: command);

      expect(preview.problem, 'error');
      expect(preview.affectedIds, isEmpty);
      expect(preview.canRun, isFalse);
    });

    test('markVisited with a null target returns problem=error, does not throw', () async {
      const command = TripCommand(kind: TripCommandKind.markVisited, target: null);

      final preview = await executor.preview(tripId: 't1', command: command);

      expect(preview.problem, 'error');
      expect(preview.affectedIds, isEmpty);
      expect(preview.canRun, isFalse);
    });
  });

  group('regression: real target behavior is unchanged', () {
    const command = TripCommand(kind: TripCommandKind.deleteStop, target: 'مطعم بغداد');

    setUp(() {
      when(() => db.query('stops', where: 'trip_id = ?', whereArgs: ['t1']))
          .thenAnswer((_) async => [
                {'id': 's1', 'name': 'مطعم بغداد', 'name_en': 'Baghdad Restaurant'},
                {'id': 's2', 'name': 'حديقة الزوراء', 'name_en': 'Zawra Park'},
              ]);
    });

    test('a single match resolves normally', () async {
      final preview = await executor.preview(tripId: 't1', command: command);

      expect(preview.problem, isNull);
      expect(preview.affectedIds, ['s1']);
      expect(preview.targetLabel, 'مطعم بغداد');
      expect(preview.canRun, isTrue);
    });

    test('no match returns not-found with the target as the label', () async {
      final noMatch = TripCommand(kind: command.kind, target: 'مكان غير موجود');

      final preview = await executor.preview(tripId: 't1', command: noMatch);

      expect(preview.problem, 'not-found');
      expect(preview.targetLabel, 'مكان غير موجود');
      expect(preview.affectedIds, isEmpty);
    });

    test('multiple matches return ambiguous', () async {
      when(() => db.query('stops', where: 'trip_id = ?', whereArgs: ['t2']))
          .thenAnswer((_) async => [
                {'id': 's3', 'name': 'مطعم شام الأصيل', 'name_en': null},
                {'id': 's4', 'name': 'مطعم شام دمشق', 'name_en': null},
              ]);
      final ambiguousCommand = TripCommand(kind: command.kind, target: 'مطعم شام');

      final preview = await executor.preview(tripId: 't2', command: ambiguousCommand);

      expect(preview.problem, 'ambiguous');
      expect(preview.affectedIds, isEmpty);
    });
  });
}
