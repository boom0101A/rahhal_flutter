part of 'saved_trips_cubit.dart';

abstract class SavedTripsState extends Equatable {
  const SavedTripsState();
  @override
  List<Object?> get props => [];
}

class SavedTripsLoading extends SavedTripsState {
  const SavedTripsLoading();
}

class SavedTripsLoaded extends SavedTripsState {
  final List<TripEntity> trips;
  const SavedTripsLoaded({required this.trips});
  @override
  List<Object?> get props => [trips];
}

/// A delete the UI has already reported as done did not actually happen.
///
/// Extends [SavedTripsLoaded] deliberately: every existing
/// `state is SavedTripsLoaded` branch keeps matching, so this adds a signal
/// the screen can listen for without touching a single render path. Carrying
/// the trip list means the screen never blanks out over a failed delete.
class SavedTripsDeleteFailed extends SavedTripsLoaded {
  final String tripId;
  final String message;
  const SavedTripsDeleteFailed({
    required super.trips,
    required this.tripId,
    required this.message,
  });
  @override
  List<Object?> get props => [trips, tripId, message];
}

class SavedTripsError extends SavedTripsState {
  final String message;
  const SavedTripsError(this.message);
  @override
  List<Object?> get props => [message];
}
