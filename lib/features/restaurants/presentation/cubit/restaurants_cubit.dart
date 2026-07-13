import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/filter_constants.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/repositories/restaurant_repository.dart';

part 'restaurants_state.dart';

class RestaurantsCubit extends Cubit<RestaurantsState> {
  final RestaurantRepository _repository;

  RestaurantsCubit({required RestaurantRepository repository})
      : _repository = repository,
        super(const RestaurantsLoading());

  List<RestaurantEntity> _allRestaurants = [];

  Future<void> loadRestaurants(String tripId) async {
    emit(const RestaurantsLoading());

    final result = await _repository.getRestaurantsForTrip(tripId);
    result.fold(
      (failure) => emit(RestaurantsError(failure.message)),
      (restaurants) {
        _allRestaurants = restaurants;
        emit(RestaurantsLoaded(
          restaurants: restaurants,
          filteredRestaurants: restaurants,
          activeFilter: RestaurantFilter.all,
        ));
      },
    );
  }

  void applyFilter(String filterId) {
    final current = state;
    if (current is! RestaurantsLoaded) return;

    final filtered = filterId == RestaurantFilter.all
        ? _allRestaurants
        : _allRestaurants.where((r) {
            return switch (filterId) {
              RestaurantFilter.halal => r.halalCertified,
              RestaurantFilter.recommended => r.isRecommended,
              RestaurantFilter.seafood => r.cuisineType?.toLowerCase() == 'seafood' ||
                  r.cuisineType?.contains('بحري') == true,
              RestaurantFilter.traditional => r.cuisineType?.toLowerCase() == 'traditional' ||
                  r.cuisineType?.contains('تقليدي') == true,
              RestaurantFilter.modern => r.cuisineType?.toLowerCase() == 'modern' ||
                  r.cuisineType?.contains('عصري') == true,
              _ => false,
            };
          }).toList();

    emit(RestaurantsLoaded(
      restaurants: _allRestaurants,
      filteredRestaurants: filtered,
      activeFilter: filterId,
    ));
  }
}
