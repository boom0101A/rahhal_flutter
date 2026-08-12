import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/errors/failures.dart';
import 'package:rahhal_flutter/features/itinerary/domain/entities/day_entity.dart';
import 'package:rahhal_flutter/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:rahhal_flutter/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:rahhal_flutter/features/trip_planner/domain/entities/stop_entity.dart';

/// Regression test for "switching days in the itinerary looks choppy".
/// selectDay used to emit TWO states per tap — first blanking the stops
/// list with isLoadingStops:true (triggering a shimmer flash), then the
/// real stops once the (always-fast, local) SQLite read resolved. Because
/// the gap was tiny, this read as two abrupt jump-cuts rather than one
/// smooth transition. selectDay now does the fetch first and emits ONE
/// state carrying the new index and the new stops together, so the UI can
/// crossfade cleanly from the old day's content straight to the new day's.
///
/// Uses a Completer to inspect cubit.state mid-flight instead of listening
/// to cubit.stream — this project's bloc stream listeners have proven
/// unreliable/racy in tests elsewhere this session (see
/// itinerary_reorder_failure_test.dart's history), so direct synchronous
/// state inspection is the dependable way to prove "nothing changed yet".
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
  final day1 = const DayEntity(id: 'd1', tripId: 't1', dayNumber: 1);
  final day2 = const DayEntity(id: 'd2', tripId: 't1', dayNumber: 2);

  setUp(() {
    repo = _MockRepo();
    cubit = ItineraryCubit(repository: repo);
  });

  Future<void> loadInitial() async {
    when(() => repo.getDaysForTrip('t1')).thenAnswer((_) async => Right([day1, day2]));
    when(() => repo.getStopsForDay('d1'))
        .thenAnswer((_) async => Right([_stop('a', 'd1', 0)]));
    await cubit.loadItinerary('t1');
  }

  test('selectDay does not blank/switch state before the fetch resolves, then '
      'lands on the new index+stops together', () async {
    await loadInitial();
    final completer = Completer<Either<Failure, List<StopEntity>>>();
    when(() => repo.getStopsForDay('d2')).thenAnswer((_) => completer.future);

    final pending = cubit.selectDay(1); // not awaited yet

    // Let selectDay run up to its `await` on the repository call, without
    // letting that call resolve.
    await Future<void>.delayed(Duration.zero);

    final midFlight = cubit.state as ItineraryLoaded;
    expect(midFlight.selectedDayIndex, 0,
        reason: 'must not switch to the new day until real data is ready');
    expect(midFlight.selectedDayStops.map((s) => s.id), ['a'],
        reason: 'the old day\'s real stops must still be showing — the old '
            'code blanked this to [] immediately, causing the shimmer flash');

    completer.complete(Right([_stop('b', 'd2', 0), _stop('c', 'd2', 1)]));
    await pending;

    final settled = cubit.state as ItineraryLoaded;
    expect(settled.selectedDayIndex, 1);
    expect(settled.selectedDayStops.map((s) => s.id), ['b', 'c']);
  });

  test('selectDay with the SAME index still re-fetches (protects reorderStops)',
      () async {
    // reorderStops calls selectDay(current.selectedDayIndex) deliberately,
    // with the CURRENT index, to force a reload from SQLite after a
    // drag-and-drop write. The "same day tapped again, skip" guard belongs
    // at the UI tap site, NOT inside the cubit — if someone moves it here,
    // this test catches it by failing.
    await loadInitial();
    when(() => repo.getStopsForDay('d1'))
        .thenAnswer((_) async => Right([_stop('a-reordered', 'd1', 0)]));

    await cubit.selectDay(0);

    verify(() => repo.getStopsForDay('d1')).called(2); // initial load + this call
    expect((cubit.state as ItineraryLoaded).selectedDayStops.map((s) => s.id),
        ['a-reordered']);
  });

  test('a failed fetch lands on ItineraryError', () async {
    await loadInitial();
    when(() => repo.getStopsForDay('d2'))
        .thenAnswer((_) async => const Left(DatabaseFailure('locked')));

    await cubit.selectDay(1);

    expect(cubit.state, isA<ItineraryError>());
  });

  test('the fix is not day-count-specific — a 5-day trip with non-adjacent '
      'jumps (day 1 → day 4 → day 2 → day 5) behaves identically at every step',
      () async {
    // selectDay(dayIndex) and the widget's AnimatedSwitcher are both keyed
    // purely off the index — nothing about the implementation special-cases
    // "day 1" or "day 2". This test exercises every day of a longer trip,
    // jumping around non-sequentially, to prove that directly rather than
    // just asserting it from reading the code.
    final days = List.generate(
        5, (i) => DayEntity(id: 'd${i + 1}', tripId: 't1', dayNumber: i + 1));
    when(() => repo.getDaysForTrip('t1')).thenAnswer((_) async => Right(days));
    for (final d in days) {
      when(() => repo.getStopsForDay(d.id))
          .thenAnswer((_) async => Right([_stop('s-${d.id}', d.id, 0)]));
    }
    await cubit.loadItinerary('t1');
    expect((cubit.state as ItineraryLoaded).selectedDayIndex, 0);

    for (final targetIndex in [3, 1, 4, 0, 2]) {
      final completer = Completer<Either<Failure, List<StopEntity>>>();
      final targetDay = days[targetIndex];
      when(() => repo.getStopsForDay(targetDay.id))
          .thenAnswer((_) => completer.future);

      final pending = cubit.selectDay(targetIndex);
      await Future<void>.delayed(Duration.zero);

      // Same guarantee as the 2-day case, re-checked at every jump: the
      // switch doesn't happen (index or stops) until data is ready.
      final beforeIndex = (cubit.state as ItineraryLoaded).selectedDayIndex;
      expect(beforeIndex, isNot(targetIndex),
          reason: 'day $targetIndex must not be "selected" before its stops '
              'actually arrive');

      completer.complete(Right([_stop('s-${targetDay.id}-loaded', targetDay.id, 0)]));
      await pending;

      final settled = cubit.state as ItineraryLoaded;
      expect(settled.selectedDayIndex, targetIndex);
      expect(settled.selectedDayStops.single.id, 's-${targetDay.id}-loaded');
    }
  });
}
