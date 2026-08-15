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
  late _MockSync sync;
  late TripCommandExecutor executor;

  setUp(() {
    db = _MockDb();
    sync = _MockSync();
    when(() => sync.markTripDirtyAndSync(any())).thenAnswer((_) async {});
    executor = TripCommandExecutor(dbHelper: db, syncService: sync);
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

  group('apply() reflects whether a row was actually changed', () {
    // Simulates the target having already been removed by something else
    // (another device's sync, another command) between preview and this
    // confirmation — the doc comment on apply() promises `false` here, but
    // it used to unconditionally return `true` regardless of row count.
    test('deleteStop returns false when 0 rows were actually deleted', () async {
      when(() => db.delete('stops', where: 'id = ?', whereArgs: ['s1']))
          .thenAnswer((_) async => 0);
      final preview = TripCommandPreview(
        command: const TripCommand(kind: TripCommandKind.deleteStop, target: 'x'),
        tripId: 't1',
        targetLabel: 'x',
        affectedIds: const ['s1'],
      );

      final ok = await executor.apply(preview);

      expect(ok, isFalse);
      verifyNever(() => sync.markTripDirtyAndSync(any()));
    });

    test('deleteStop returns true when a row was actually deleted', () async {
      when(() => db.delete('stops', where: 'id = ?', whereArgs: ['s1']))
          .thenAnswer((_) async => 1);
      final preview = TripCommandPreview(
        command: const TripCommand(kind: TripCommandKind.deleteStop, target: 'x'),
        tripId: 't1',
        targetLabel: 'x',
        affectedIds: const ['s1'],
      );

      final ok = await executor.apply(preview);

      expect(ok, isTrue);
    });

    test('markVisited returns false when 0 rows were actually updated', () async {
      when(() => db.update('stops', {'is_visited': 1}, where: 'id = ?', whereArgs: ['s1']))
          .thenAnswer((_) async => 0);
      final preview = TripCommandPreview(
        command: const TripCommand(kind: TripCommandKind.markVisited, target: 'x'),
        tripId: 't1',
        targetLabel: 'x',
        affectedIds: const ['s1'],
      );

      final ok = await executor.apply(preview);

      expect(ok, isFalse);
      verifyNever(() => sync.markTripDirtyAndSync(any()));
    });

    test('markVisited returns true when a row was actually updated', () async {
      when(() => db.update('stops', {'is_visited': 1}, where: 'id = ?', whereArgs: ['s1']))
          .thenAnswer((_) async => 1);
      final preview = TripCommandPreview(
        command: const TripCommand(kind: TripCommandKind.markVisited, target: 'x'),
        tripId: 't1',
        targetLabel: 'x',
        affectedIds: const ['s1'],
      );

      final ok = await executor.apply(preview);

      expect(ok, isTrue);
    });

    test('deleteDay returns false when 0 day rows were actually deleted', () async {
      when(() => db.executeInTransaction<int>(any())).thenAnswer((_) async => 0);
      final preview = TripCommandPreview(
        command: const TripCommand(kind: TripCommandKind.deleteDay, dayNumber: 1),
        tripId: 't1',
        targetLabel: '1|2',
        affectedIds: const ['d1'],
      );

      final ok = await executor.apply(preview);

      expect(ok, isFalse);
      verifyNever(() => sync.markTripDirtyAndSync(any()));
    });

    test('deleteDay returns true when the day row was actually deleted', () async {
      when(() => db.executeInTransaction<int>(any())).thenAnswer((_) async => 1);
      final preview = TripCommandPreview(
        command: const TripCommand(kind: TripCommandKind.deleteDay, dayNumber: 1),
        tripId: 't1',
        targetLabel: '1|2',
        affectedIds: const ['d1'],
      );

      final ok = await executor.apply(preview);

      expect(ok, isTrue);
    });
  });
}
