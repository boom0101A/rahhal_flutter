import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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
      (stops) async {
        _allStops = stops;

        // Try to get user location non-blocking
        LatLng? userLocation;
        try {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 5),
              ),
            );
            userLocation = LatLng(pos.latitude, pos.longitude);
          }
        } catch (_) {} // Silently ignore — location is optional

        emit(MapReady(
          stops: stops,
          filteredStops: stops,
          userLocation: userLocation,
        ));
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
