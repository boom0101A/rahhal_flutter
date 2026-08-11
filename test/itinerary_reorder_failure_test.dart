import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/errors/failures.dart';
import 'package:rahhal_flutter/features/itinerary/domain/entities/day_entity.dart';
import 'package:rahhal_flutter/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:rahhal_flutter/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:rahhal_flutter/features/trip_planner/domain/entities/stop_entity.dart';

/// Regression test for "a failed drag-and-drop reorder silently snapped back
/// with no explanation." reorderStops used to discard the repository's
/// Either entirely, then unconditionally reload from SQLite — which, on a
/// failed write, pulls back the OLD order with nothing telling the user why.
class _MockRepo extends Mock implements ItineraryRepository {}

StopEntity _stop(String id, int order) => StopEntity(
      id: id,
      dayId: 'd1',
      tripId: 't1',
      orderIndex: order,
      name: 's-$id',
      category: 'other',
      timeOfDay: 'morning',
      durationMinutes: 60,
      latitude: 0,
      longitude: 0,
      costUsd: 0,
      bookingRequired: false,
      isVisited: false,
    );

void main() {
  // The state-transition logic in isolation: pure, deterministic, no Cubit/
  // stream machinery needed to prove it's wired correctly.
  group('ItineraryLoaded.withError / clearError', () {
    final base = ItineraryLoaded(
      days: const [DayEntity(id: 'd1', tripId: 't1', dayNumber: 1)],
      selectedDayIndex: 0,
      selectedDayStops: [_stop('a', 0)],
    );

    test('withError sets the message and keeps every other field', () {
      final withErr = base.withError('locked');
      expect(withErr.actionError, 'locked');
      expect(withErr.selectedDayStops, base.selectedDayStops);
      expect(withErr.days, base.days);
    });

    test('clearError removes the message and keeps the stops', () {
      final cleared = base.withError('locked').clearError();
      expect(cleared.actionError, isNull);
      expect(cleared.selectedDayStops, base.selectedDayStops);
    });
  });

  group('ItineraryCubit.reorderStops', () {
    late _MockRepo repo;
    late ItineraryCubit cubit;
    final day = const DayEntity(id: 'd1', tripId: 't1', dayNumber: 1);

    setUp(() {
      repo = _MockRepo();
      cubit = ItineraryCubit(repository: repo);
    });

    Future<void> loadInitial(List<StopEntity> stops) async {
      when(() => repo.getDaysForTrip('t1')).thenAnswer((_) async => Right([day]));
      when(() => repo.getStopsForDay('d1')).thenAnswer((_) async => Right(stops));
      await cubit.loadItinerary('t1');
    }

    test('a failed reorder is not silently discarded — the repository result is inspected',
        () async {
      await loadInitial([_stop('a', 0), _stop('b', 1)]);

      // any(), not a literal ['b','a'] — Dart's List.== is identity, not
      // value, equality, so a literal here would silently never match the
      // literal the cubit actually passes and the stub would never fire.
      when(() => repo.reorderStops(any(), any()))
          .thenAnswer((_) async => const Left(DatabaseFailure('locked')));

      // Must complete without throwing — the old code (and a naive fix that
      // forgot the isClosed guard or mishandled the Either) could leave this
      // hanging or crash on an unawaited/rethrown failure.
      await cubit.reorderStops('d1', ['b', 'a']);

      verify(() => repo.reorderStops(any(), any())).called(1);
      // selectDay's reload still runs regardless of success/failure (it's
      // what pulls the real, current order back from SQLite either way).
      verify(() => repo.getStopsForDay('d1')).called(2); // initial load + reload
      expect(cubit.state, isA<ItineraryLoaded>(),
          reason: 'a failed reorder must not leave the cubit on ItineraryError '
              '— the trip is still perfectly loaded, just one write failed');
    });

    test('a successful reorder completes cleanly with no actionError',
        () async {
      await loadInitial([_stop('a', 0), _stop('b', 1)]);
      when(() => repo.reorderStops(any(), any()))
          .thenAnswer((_) async => const Right(null));

      await cubit.reorderStops('d1', ['b', 'a']);

      expect((cubit.state as ItineraryLoaded).actionError, isNull);
    });
  });
}
