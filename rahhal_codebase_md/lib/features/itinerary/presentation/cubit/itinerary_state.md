# ملف كود Dart: lib\features\itinerary\presentation\cubit\itinerary_state.dart

```dart
part of 'itinerary_cubit.dart';

abstract class ItineraryState extends Equatable {
  const ItineraryState();
  @override
  List<Object?> get props => [];
}

class ItineraryLoading extends ItineraryState {
  const ItineraryLoading();
}

class ItineraryLoaded extends ItineraryState {
  final List<DayEntity> days;
  final int selectedDayIndex;
  final List<StopEntity> selectedDayStops;
  final bool isLoadingStops;

  const ItineraryLoaded({
    required this.days,
    required this.selectedDayIndex,
    required this.selectedDayStops,
    this.isLoadingStops = false,
  });

  DayEntity get selectedDay => days[selectedDayIndex];

  @override
  List<Object?> get props =>
      [days, selectedDayIndex, selectedDayStops, isLoadingStops];
}

class ItineraryError extends ItineraryState {
  final String message;
  const ItineraryError(this.message);
  @override
  List<Object?> get props => [message];
}

```
