import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/database/database_helper.dart';
import 'package:rahhal_flutter/features/auth/domain/entities/user_entity.dart';
import 'package:rahhal_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:rahhal_flutter/features/favorites/data/favorites_repository_impl.dart';

/// Regression test for "two accounts on one device wreck each other's
/// favourites".
///
/// Only the INSERT was ever stamped with `user_id`; every lookup matched on
/// `item_type + item_ref_id` alone. So account B tapping the heart on an item
/// account A had favourited matched A's row, deleted it, and gave B nothing.
/// `updateNotes` overwrote A's note the same way.
///
/// The second, quieter half: `getFavorites` passed `where: null` when nobody
/// was signed in, which returned every account's rows at once.
///
/// These assert on the generated SQL rather than on results, because
/// DatabaseHelper is a singleton that opens a real file — there is no
/// sqflite_common_ffi in this project, so the clause itself is what's testable.
class _MockDb extends Mock implements DatabaseHelper {}

class _MockAuth extends Mock implements AuthRepository {}

const _uid = 'user-abc';

void main() {
  late _MockDb db;
  late _MockAuth auth;
  late FavoritesRepositoryImpl repo;

  setUp(() {
    db = _MockDb();
    auth = _MockAuth();
    repo = FavoritesRepositoryImpl(dbHelper: db, authRepository: auth);

    when(() => db.query(any(),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
        orderBy: any(named: 'orderBy'))).thenAnswer((_) async => []);
    when(() => db.delete(any(),
            where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
        .thenAnswer((_) async => 1);
    when(() => db.update(any(), any(),
            where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
        .thenAnswer((_) async => 1);
  });

  void signedIn() => when(() => auth.getCurrentUser())
      .thenReturn(const UserEntity(uid: _uid, isAnonymous: false));
  void signedOut() => when(() => auth.getCurrentUser()).thenReturn(null);

  ({String? where, List<Object?>? args}) lastQuery() {
    final captured = verify(() => db.query(any(),
        where: captureAny(named: 'where'),
        whereArgs: captureAny(named: 'whereArgs'),
        orderBy: any(named: 'orderBy'))).captured;
    return (
      where: captured[captured.length - 2] as String?,
      args: captured.last as List<Object?>?,
    );
  }

  group('getFavorites', () {
    test('signed in reads only that account\'s rows', () async {
      signedIn();
      await repo.getFavorites();

      final q = lastQuery();
      expect(q.where, 'user_id = ?');
      expect(q.args, [_uid]);
    });

    test('signed out uses IS NULL, not a null argument', () async {
      signedOut();
      await repo.getFavorites();

      final q = lastQuery();
      // `user_id = ?` with a null arg is never true in SQL, so the signed-out
      // user would see nothing at all. And the old `where: null` showed them
      // everyone's rows — the bug being fixed.
      expect(q.where, 'user_id IS NULL');
      expect(q.args, isEmpty);
    });
  });

  group('toggleFavorite', () {
    test('scopes the lookup to the account', () async {
      signedIn();
      await repo.toggleFavorite('stop', 'stop-1', tripId: 'trip-1');

      final q = lastQuery();
      expect(q.where, 'item_type = ? AND item_ref_id = ? AND user_id = ?');
      expect(q.args, ['stop', 'stop-1', _uid]);
    });

    test('the delete uses the exact same clause as the lookup', () async {
      signedIn();
      when(() => db.query('favorites',
              where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
          .thenAnswer((_) async => [
                {'id': 'fav-1'}
              ]);

      await repo.toggleFavorite('restaurant', 'rest-9', tripId: 'trip-1');

      final lookup = lastQuery();
      final deleted = verify(() => db.delete('favorites',
          where: captureAny(named: 'where'),
          whereArgs: captureAny(named: 'whereArgs'))).captured;

      // If these two ever drift apart, a tap finds nothing and then deletes
      // somebody else's row — which is precisely how this bug behaved.
      expect(deleted.first, lookup.where);
      expect(deleted.last, lookup.args);
    });

    test('a new row is still stamped with the owner', () async {
      signedIn();
      when(() => db.insert(any(), any())).thenAnswer((_) async => 1);

      await repo.toggleFavorite('hotel', 'hotel-3', tripId: 'trip-1');

      final row = verify(() => db.insert('favorites', captureAny())).captured
          .single as Map<String, dynamic>;
      expect(row['user_id'], _uid);
      expect(row['trip_id'], 'trip-1');
    });
  });

  test('updateNotes cannot overwrite another account\'s note', () async {
    signedIn();
    await repo.updateNotes('stop', 'stop-4', 'mine');

    final captured = verify(() => db.update('favorites', any(),
        where: captureAny(named: 'where'),
        whereArgs: captureAny(named: 'whereArgs'))).captured;
    expect(captured.first, 'item_type = ? AND item_ref_id = ? AND user_id = ?');
    expect(captured.last, ['stop', 'stop-4', _uid]);
  });

  test('isFavorite is scoped too, even though nothing calls it yet', () async {
    signedIn();
    await repo.isFavorite('stop', 'stop-7');

    final q = lastQuery();
    expect(q.where, contains('user_id = ?'));
    expect(q.args, ['stop', 'stop-7', _uid]);
  });
}
