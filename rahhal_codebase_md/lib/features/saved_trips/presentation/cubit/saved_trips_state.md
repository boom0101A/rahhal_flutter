# ملف كود Dart: lib\features\saved_trips\presentation\cubit\saved_trips_state.dart

```dart
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

class SavedTripsError extends SavedTripsState {
  final String message;
  const SavedTripsError(this.message);
  @override
  List<Object?> get props => [message];
}

```
