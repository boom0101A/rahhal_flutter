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
    result.fold(
      (failure) => emit(SavedTripsError(failure.message)),
      (trips) => emit(SavedTripsLoaded(trips: trips)),
    );
  }

  Future<void> deleteTrip(String tripId) async {
    final result = await _repository.deleteTrip(tripId);
    result.fold(
      (failure) => null,
      (_) => loadTrips(),
    );
  }

  Future<void> updateStatus(String tripId, String status) async {
    await _repository.updateTripStatus(tripId, status);
    await loadTrips();
  }
}
