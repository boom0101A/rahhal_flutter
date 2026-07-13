import 'package:equatable/equatable.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';
import '../../../restaurants/domain/entities/restaurant_entity.dart';
import 'favorite_entity.dart';

class FavoriteItem extends Equatable {
  final FavoriteEntity favorite;
  final StopEntity? stop;
  final RestaurantEntity? restaurant;

  const FavoriteItem({
    required this.favorite,
    this.stop,
    this.restaurant,
  });

  @override
  List<Object?> get props => [favorite, stop, restaurant];
}
