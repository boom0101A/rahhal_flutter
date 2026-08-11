import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/entities/trip_entity.dart';

part 'saved_trips_state.dart';

class SavedTripsCubit extends Cubit<SavedTripsState> {
  final TripRepository _repository;

  SavedTripsCubit({required TripRepository repository})
      : _repository = repository,
        super(const SavedTripsLoading());

  Future<void> loadTrips() async {
    emit(const SavedTripsLoading());
    final result = await _repository.getAllTrips();
    if (isClosed) return;
    result.fold(
      (failure) => emit(SavedTripsError(failure.message)),
      (trips) => emit(SavedTripsLoaded(trips: trips)),
    );
  }

  Future<void> deleteTrip(String tripId) async {
    final before = state;
    final result = await _repository.deleteTrip(tripId);
    if (isClosed) return;
    await result.fold(
      (failure) async {
        // Was `(failure) => null`. By the time this runs the screen has already
        // hidden the card and the snackbar has said "deleted", so staying
        // quiet here is a lie: the trip simply reappears on the next load with
        // no explanation. No emit(Loading) on this path, so the list doesn't
        // flash a shimmer on the way to an error.
        emit(SavedTripsDeleteFailed(
          trips: before is SavedTripsLoaded ? before.trips : const [],
          tripId: tripId,
          message: failure.message,
        ));
        // Degenerate case only — a delete that raced a reload leaves us with no
        // list to carry forward, and an empty screen would be its own bug.
        if (before is! SavedTripsLoaded) await loadTrips();
      },
      (_) async => loadTrips(),
    );
  }

  Future<void> updateStatus(String tripId, String status) async {
    final before = state;
    final result = await _repository.updateTripStatus(tripId, status);
    if (isClosed) return;
    // The Either used to be discarded outright, so a failed status change
    // reloaded silently and just reverted with no explanation — the same
    // defect deleteTrip above was fixed for.
    await result.fold(
      (failure) async {
        emit(SavedTripsStatusUpdateFailed(
          trips: before is SavedTripsLoaded ? before.trips : const [],
          tripId: tripId,
          message: failure.message,
        ));
        if (before is! SavedTripsLoaded) await loadTrips();
      },
      (_) async => loadTrips(),
    );
  }
}
