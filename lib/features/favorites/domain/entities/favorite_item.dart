import 'package:equatable/equatable.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';
import '../../../restaurants/domain/entities/restaurant_entity.dart';
import '../../../hotels/domain/entities/hotel_entity.dart';
import 'favorite_entity.dart';

class FavoriteItem extends Equatable {
  final FavoriteEntity favorite;
  final StopEntity? stop;
  final RestaurantEntity? restaurant;
  final HotelEntity? hotel;

  /// The owning trip's real destination city (looked up via the item's
  /// tripId), used to group favorites by destination — distinct from
  /// [FavoriteEntity.destinationName], which callers currently populate
  /// with the item's own name rather than a destination.
  final String? tripDestination;

  const FavoriteItem({
    required this.favorite,
    this.stop,
    this.restaurant,
    this.hotel,
    this.tripDestination,
  });

  @override
  List<Object?> get props => [favorite, stop, restaurant, hotel, tripDestination];
}
