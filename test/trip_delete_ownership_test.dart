import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/database/database_helper.dart';
import 'package:rahhal_flutter/core/network/ai_service.dart';
import 'package:rahhal_flutter/core/network/cloud_sync_service.dart';
import 'package:rahhal_flutter/features/trip_planner/data/trip_repository_impl.dart';

/// Regression test for "the delete reported success but nothing was deleted".
///
/// `deleteTrip` returned `Right(null)` whenever its ownership check found
/// nothing — which covered two very different situations with one answer:
/// a trip that is already gone (fine, the user's intent is satisfied) and a
/// trip that exists but belongs to another account (not fine at all). Paired
/// with a cubit that discarded the failure branch, a delete that did nothing
/// was indistinguishable from one that worked.
///
/// Asserted through a mocked DatabaseHelper: it is a singleton that opens a
/// real file, and there is no sqflite_common_ffi in this project.
class _MockDb extends Mock implements DatabaseHelper {}

class _MockAi extends Mock implements AITravelService {}

class _MockSync extends Mock implements CloudSyncService {}

void main() {
  late _MockDb db;
  late TripRepositoryImpl repo;

  setUp(() {
    db = _MockDb();
    repo = TripRepositoryImpl(
      dbHelper: db,
      aiService: _MockAi(),
      syncService: _MockSync(),
    );
  });

  /// Stubs the ownership probe (`id = ? AND user_id = ?`) and the existence
  /// probe (`id = ?`) separately, which is the whole point of the fix.
  void stubLookups({
    Map<String, dynamic>? owned,
    Map<String, dynamic>? exists,
  }) {
    when(() => db.queryOne('trips',
        where: any(named: 'where', that: contains('user_id')),
        whereArgs: any(named: 'whereArgs'))).thenAnswer((_) async => owned);
    when(() => db.queryOne('trips',
        where: 'id = ?',
        whereArgs: any(named: 'whereArgs'))).thenAnswer((_) async => exists);
  }

  test('a trip that exists but belongs to another account fails loudly',
      () async {
    // Firebase isn't initialised in tests, so _currentUid is null and the
    // ownership probe misses — exactly the shape of the real bug.
    stubLookups(owned: null, exists: {'id': 't1', 'user_id': 'someone-else'});

    final result = await repo.deleteTrip('t1');

    expect(result.isLeft(), isTrue,
        reason: 'reporting success for a row that was never touched is what '
            'made the trip silently reappear');
    verifyNever(() => db.executeInTransaction(any()));
  });

  test('a trip that no longer exists is still a success', () async {
    // A double tap, or a cloud delete that already landed. The user's intent
    // is satisfied, so surfacing a red error here would be wrong.
    stubLookups(owned: null, exists: null);

    final result = await repo.deleteTrip('gone');

    expect(result.isRight(), isTrue);
    verifyNever(() => db.executeInTransaction(any()));
  });

  test('the existence probe only runs when the ownership check misses',
      () async {
    stubLookups(owned: {'id': 't1', 'user_id': null}, exists: null);
    when(() => db.query('trip_documents',
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'))).thenAnswer((_) async => []);
    when(() => db.executeInTransaction<void>(any())).thenAnswer((_) async {});
    when(() => db.insert(any(), any())).thenAnswer((_) async => 1);
    when(() => _MockSync().deleteTripFromCloud(any()))
        .thenAnswer((_) async {});

    await repo.deleteTrip('t1');

    verifyNever(() =>
        db.queryOne('trips', where: 'id = ?', whereArgs: any(named: 'whereArgs')));
  });
}
