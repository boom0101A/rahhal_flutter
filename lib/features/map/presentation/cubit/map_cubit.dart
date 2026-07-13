import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/map_repository.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';

part 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final MapRepository _repository;

  MapCubit({required MapRepository repository})
      : _repository = repository,
        super(const MapLoading());

  List<StopEntity> _allStops = [];

  Future<void> loadMapData(String tripId) async {
    emit(const MapLoading());
    final result = await _repository.getStopsForTrip(tripId);
    result.fold(
      (failure) => emit(MapError(failure.message)),
      (stops) {
        _allStops = stops;
        emit(MapReady(stops: stops, filteredStops: stops));
      },
    );
  }

  void selectStop(String? stopId) {
    final current = state;
    if (current is! MapReady) return;
    emit(current.copyWith(selectedStopId: stopId));
  }

  void clearSelection() {
    final current = state;
    if (current is! MapReady) return;
    emit(current.copyWith(selectedStopId: null));
  }

  void filterByDay(String? dayId) {
    final current = state;
    if (current is! MapReady) return;

    final filtered = dayId == null
        ? _allStops
        : _allStops.where((s) => s.dayId == dayId).toList();

    emit(current.copyWith(filteredStops: filtered, selectedStopId: null));
  }
}
