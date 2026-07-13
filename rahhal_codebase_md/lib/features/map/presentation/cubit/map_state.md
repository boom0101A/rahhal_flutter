# ملف كود Dart: lib\features\map\presentation\cubit\map_state.dart

```dart
part of 'map_cubit.dart';

abstract class MapState extends Equatable {
  const MapState();
  @override
  List<Object?> get props => [];
}

class MapLoading extends MapState {
  const MapLoading();
}

class MapReady extends MapState {
  final List<StopEntity> stops;
  final List<StopEntity> filteredStops;
  final String? selectedStopId;

  const MapReady({
    required this.stops,
    required this.filteredStops,
    this.selectedStopId,
  });

  StopEntity? get selectedStop => selectedStopId == null
      ? null
      : filteredStops.where((s) => s.id == selectedStopId).firstOrNull;

  MapReady copyWith({
    List<StopEntity>? stops,
    List<StopEntity>? filteredStops,
    String? selectedStopId,
  }) {
    return MapReady(
      stops: stops ?? this.stops,
      filteredStops: filteredStops ?? this.filteredStops,
      selectedStopId: selectedStopId,
    );
  }

  @override
  List<Object?> get props => [stops, filteredStops, selectedStopId];
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);
  @override
  List<Object?> get props => [message];
}

```
