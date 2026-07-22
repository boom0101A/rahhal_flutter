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

  int get visitedCount => selectedDayStops.where((s) => s.isVisited).length;

  ItineraryLoaded copyWith({
    List<DayEntity>? days,
    int? selectedDayIndex,
    List<StopEntity>? selectedDayStops,
    bool? isLoadingStops,
  }) =>
      ItineraryLoaded(
        days: days ?? this.days,
        selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
        selectedDayStops: selectedDayStops ?? this.selectedDayStops,
        isLoadingStops: isLoadingStops ?? this.isLoadingStops,
      );

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
