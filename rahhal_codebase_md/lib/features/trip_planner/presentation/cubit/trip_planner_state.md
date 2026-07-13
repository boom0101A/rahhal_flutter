# ملف كود Dart: lib\features\trip_planner\presentation\cubit\trip_planner_state.dart

```dart
part of 'trip_planner_cubit.dart';

abstract class TripPlannerState extends Equatable {
  const TripPlannerState();
  @override
  List<Object?> get props => [];
}

class TripPlannerInitial extends TripPlannerState {
  const TripPlannerInitial();
}

class TripPlannerGenerating extends TripPlannerState {
  const TripPlannerGenerating();
}

class TripPlannerSuccess extends TripPlannerState {
  final TripEntity trip;
  const TripPlannerSuccess(this.trip);
  @override
  List<Object?> get props => [trip];
}

class TripPlannerError extends TripPlannerState {
  final String message;
  const TripPlannerError(this.message);
  @override
  List<Object?> get props => [message];
}

```
