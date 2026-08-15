import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/errors/failures.dart';
import 'package:rahhal_flutter/core/services/analytics_service.dart';
import 'package:rahhal_flutter/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:rahhal_flutter/features/favorites/presentation/cubit/favorites_cubit.dart';

/// Regression test: toggleFavorite had no guard against a rapid double-tap
/// on the same item. The repository does a read-then-write with no DB-level
/// uniqueness, so two concurrent calls for the same key could both see
/// "not favorited yet" and each insert their own row — a duplicated
/// favorite. FavoritesCubit now ignores a second call for a key that's
/// already in flight.
class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late _MockFavoritesRepository repo;
  late _MockAnalyticsService analytics;
  late FavoritesCubit cubit;

  setUp(() {
    repo = _MockFavoritesRepository();
    analytics = _MockAnalyticsService();
    when(() => analytics.logFavoriteToggle(
          itemType: any(named: 'itemType'),
          itemId: any(named: 'itemId'),
          isFavorited: any(named: 'isFavorited'),
        )).thenAnswer((_) async {});
    cubit = FavoritesCubit(repository: repo, analytics: analytics);
    when(() => repo.getFavorites()).thenAnswer((_) async => const Right([]));
  });

  test('a second tap on the same item while the first is in flight is ignored',
      () async {
    final completer = Completer<Either<Failure, void>>();
    when(() => repo.toggleFavorite('stop', 's1',
            tripId: 't1', destinationName: null, notes: null))
        .thenAnswer((_) => completer.future);

    final first = cubit.toggleFavorite('stop', 's1', tripId: 't1');
    final second = cubit.toggleFavorite('stop', 's1', tripId: 't1');

    completer.complete(const Right(null));
    await first;
    await second;

    verify(() => repo.toggleFavorite('stop', 's1',
        tripId: 't1', destinationName: null, notes: null)).called(1);
  });

  test('a tap on a different item while another is in flight is NOT blocked',
      () async {
    final completer1 = Completer<Either<Failure, void>>();
    when(() => repo.toggleFavorite('stop', 's1',
            tripId: 't1', destinationName: null, notes: null))
        .thenAnswer((_) => completer1.future);
    when(() => repo.toggleFavorite('stop', 's2',
            tripId: 't1', destinationName: null, notes: null))
        .thenAnswer((_) async => const Right(null));

    final first = cubit.toggleFavorite('stop', 's1', tripId: 't1');
    await cubit.toggleFavorite('stop', 's2', tripId: 't1');

    completer1.complete(const Right(null));
    await first;

    verify(() => repo.toggleFavorite('stop', 's1',
        tripId: 't1', destinationName: null, notes: null)).called(1);
    verify(() => repo.toggleFavorite('stop', 's2',
        tripId: 't1', destinationName: null, notes: null)).called(1);
  });

  test('after the first toggle resolves, a later tap on the same item works again',
      () async {
    when(() => repo.toggleFavorite('stop', 's1',
            tripId: 't1', destinationName: null, notes: null))
        .thenAnswer((_) async => const Right(null));

    await cubit.toggleFavorite('stop', 's1', tripId: 't1');
    await cubit.toggleFavorite('stop', 's1', tripId: 't1');

    verify(() => repo.toggleFavorite('stop', 's1',
        tripId: 't1', destinationName: null, notes: null)).called(2);
  });
}
