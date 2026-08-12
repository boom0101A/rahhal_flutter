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

  /// Set when reorderStops fails — the reload that follows it pulls the
  /// OLD order back from SQLite (nothing was actually persisted), which
  /// without this looked like a drag-and-drop that silently snapped back
  /// for no reason.
  final String? actionError;

  const ItineraryLoaded({
    required this.days,
    required this.selectedDayIndex,
    required this.selectedDayStops,
    this.actionError,
  });

  DayEntity get selectedDay => days[selectedDayIndex];

  int get visitedCount => selectedDayStops.where((s) => s.isVisited).length;

  ItineraryLoaded copyWith({
    List<DayEntity>? days,
    int? selectedDayIndex,
    List<StopEntity>? selectedDayStops,
  }) =>
      ItineraryLoaded(
        days: days ?? this.days,
        selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
        selectedDayStops: selectedDayStops ?? this.selectedDayStops,
      );

  ItineraryLoaded withError(String message) => ItineraryLoaded(
        days: days,
        selectedDayIndex: selectedDayIndex,
        selectedDayStops: selectedDayStops,
        actionError: message,
      );

  ItineraryLoaded clearError() => copyWith();

  @override
  List<Object?> get props =>
      [days, selectedDayIndex, selectedDayStops, actionError];
}

class ItineraryError extends ItineraryState {
  final String message;
  const ItineraryError(this.message);
  @override
  List<Object?> get props => [message];
}
