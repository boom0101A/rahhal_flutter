# ملف كود Dart: lib\features\restaurants\presentation\cubit\restaurants_cubit.dart

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/repositories/restaurant_repository.dart';

part 'restaurants_state.dart';

class RestaurantsCubit extends Cubit<RestaurantsState> {
  final RestaurantRepository _repository;

  RestaurantsCubit({required RestaurantRepository repository})
      : _repository = repository,
        super(const RestaurantsLoading());

  String? _currentTripId;
  List<RestaurantEntity> _allRestaurants = [];

  Future<void> loadRestaurants(String tripId) async {
    _currentTripId = tripId;
    emit(const RestaurantsLoading());

    final result = await _repository.getRestaurantsForTrip(tripId);
    result.fold(
      (failure) => emit(RestaurantsError(failure.message)),
      (restaurants) {
        _allRestaurants = restaurants;
        emit(RestaurantsLoaded(
          restaurants: restaurants,
          filteredRestaurants: restaurants,
          activeFilter: 'الكل',
        ));
      },
    );
  }

  void applyFilter(String filter) {
    final current = state;
    if (current is! RestaurantsLoaded) return;

    final filtered = filter == 'الكل'
        ? _allRestaurants
        : _allRestaurants.where((r) {
            return switch (filter) {
              'حلال' => r.halalCertified,
              'موصى به' => r.isRecommended,
              _ => r.tags.contains(filter) ||
                  r.cuisineType == filter,
            };
          }).toList();

    emit(RestaurantsLoaded(
      restaurants: _allRestaurants,
      filteredRestaurants: filtered,
      activeFilter: filter,
    ));
  }
}

```
