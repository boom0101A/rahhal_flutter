import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/errors/failures.dart';
import 'package:rahhal_flutter/features/itinerary/domain/entities/day_entity.dart';
import 'package:rahhal_flutter/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:rahhal_flutter/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:rahhal_flutter/features/trip_planner/domain/entities/stop_entity.dart';

/// Regression test: reorderStops captured `state.selectedDayIndex` BEFORE
/// awaiting the repository write, then reloaded that stale index once the
/// write resolved. The reorder sheet closes as soon as it saves, so a user
/// who taps a different day while that write is still in flight would see
/// the screen snap back to the day that was just reordered instead of
/// staying on the day they just selected.
class _MockRepo extends Mock implements ItineraryRepository {}

StopEntity _stop(String id, String dayId, int order) => StopEntity(
      id: id,
      dayId: dayId,
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
  late _MockRepo repo;
  late ItineraryCubit cubit;
  const day1 = DayEntity(id: 'd1', tripId: 't1', dayNumber: 1);
  const day2 = DayEntity(id: 'd2', tripId: 't1', dayNumber: 2);

  setUp(() async {
    repo = _MockRepo();
    cubit = ItineraryCubit(repository: repo);
    when(() => repo.getDaysForTrip('t1')).thenAnswer((_) async => const Right([day1, day2]));
    when(() => repo.getStopsForDay('d1'))
        .thenAnswer((_) async => Right([_stop('a', 'd1', 0), _stop('b', 'd1', 1)]));
    when(() => repo.getStopsForDay('d2'))
        .thenAnswer((_) async => Right([_stop('c', 'd2', 0)]));
    await cubit.loadItinerary('t1'); // lands on day index 0
  });

  test(
      'switching to a different day while a reorder write is still in flight '
      'is not clobbered by the reorder\'s stale day index', () async {
    final completer = Completer<Either<Failure, void>>();
    when(() => repo.reorderStops(any(), any())).thenAnswer((_) => completer.future);

    // Starts while selectedDayIndex == 0 — this Future is deliberately not
    // awaited yet, mirroring the sheet closing before the write resolves.
    final reorderFuture = cubit.reorderStops('d1', ['b', 'a']);

    // The user taps day 2 while the reorder's DB write is still pending.
    await cubit.selectDay(1);
    expect((cubit.state as ItineraryLoaded).selectedDayIndex, 1);

    // The reorder write now finally resolves.
    completer.complete(const Right(null));
    await reorderFuture;

    expect((cubit.state as ItineraryLoaded).selectedDayIndex, 1,
        reason: 'must stay on the day the user switched to, not snap back '
            'to the day that was being reordered');
  });

  test('reorderStops with no intervening day switch still reselects its own day',
      () async {
    when(() => repo.reorderStops(any(), any())).thenAnswer((_) async => const Right(null));

    await cubit.reorderStops('d1', ['b', 'a']);

    expect((cubit.state as ItineraryLoaded).selectedDayIndex, 0);
  });
}
