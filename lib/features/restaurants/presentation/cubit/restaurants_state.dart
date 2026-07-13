part of 'restaurants_cubit.dart';

abstract class RestaurantsState extends Equatable {
  const RestaurantsState();
  @override
  List<Object?> get props => [];
}

class RestaurantsLoading extends RestaurantsState {
  const RestaurantsLoading();
}

class RestaurantsLoaded extends RestaurantsState {
  final List<RestaurantEntity> restaurants;
  final List<RestaurantEntity> filteredRestaurants;
  final String activeFilter;

  const RestaurantsLoaded({
    required this.restaurants,
    required this.filteredRestaurants,
    required this.activeFilter,
  });

  @override
  List<Object?> get props => [restaurants, filteredRestaurants, activeFilter];
}

class RestaurantsError extends RestaurantsState {
  final String message;
  const RestaurantsError(this.message);
  @override
  List<Object?> get props => [message];
}
