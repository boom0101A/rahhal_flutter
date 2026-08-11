import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/errors/failures.dart';
import 'package:rahhal_flutter/features/trip_planner/domain/entities/trip_entity.dart';
import 'package:rahhal_flutter/features/trip_planner/domain/repositories/trip_repository.dart';
import 'package:rahhal_flutter/features/trip_planner/presentation/cubit/saved_trips_cubit.dart';

/// Regression test for updateStatus discarding its repository Either
/// outright, then unconditionally reloading — a failed status change used
/// to look identical to a successful one, with the trip's status silently
/// reverting on the next load and no explanation. Mirrors the fix already
/// proven for deleteTrip (trip_delete_failure_test.dart) and
/// ItineraryCubit.reorderStops (itinerary_reorder_failure_test.dart).
class _MockTripRepository extends Mock implements TripRepository {}

TripEntity _trip(String id, String status) {
  final now = DateTime.now();
  return TripEntity(
    id: id,
    destination: 'بغداد',
    startDate: now.add(const Duration(days: 30)),
    endDate: now.add(const Duration(days: 32)),
    durationDays: 3,
    budgetTier: 'mid',
    budgetTotal: 300,
    travelStyles: const ['culture'],
    travelersCount: 2,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _MockTripRepository repo;
  late SavedTripsCubit cubit;

  setUp(() {
    repo = _MockTripRepository();
    cubit = SavedTripsCubit(repository: repo);
  });

  Future<void> loadInitial(List<TripEntity> trips) async {
    when(() => repo.getAllTrips()).thenAnswer((_) async => Right(trips));
    await cubit.loadTrips();
  }

  test('a failed status update is not silently discarded', () async {
    await loadInitial([_trip('t1', 'planned')]);

    when(() => repo.updateTripStatus('t1', 'active'))
        .thenAnswer((_) async => const Left(DatabaseFailure('locked')));

    await cubit.updateStatus('t1', 'active');

    final state = cubit.state as SavedTripsStatusUpdateFailed;
    expect(state.message, 'locked');
    expect(state.tripId, 't1');
    expect(state.trips.single.id, 't1',
        reason: 'the list must survive the failure, not blank out');
  });

  test('a successful status update reloads with no error', () async {
    await loadInitial([_trip('t1', 'planned')]);

    when(() => repo.updateTripStatus('t1', 'active'))
        .thenAnswer((_) async => const Right(null));
    when(() => repo.getAllTrips())
        .thenAnswer((_) async => Right([_trip('t1', 'active')]));

    await cubit.updateStatus('t1', 'active');

    expect(cubit.state, isA<SavedTripsLoaded>());
    expect(cubit.state, isNot(isA<SavedTripsStatusUpdateFailed>()));
  });
}
