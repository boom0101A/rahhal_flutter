import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/favorite_item.dart';

abstract class FavoritesRepository {
  Future<Either<Failure, List<FavoriteItem>>> getFavorites();
  Future<Either<Failure, void>> toggleFavorite(
    String itemType,
    String itemRefId, {
    String? destinationName,
    String? notes,
  });
  Future<Either<Failure, bool>> isFavorite(String itemType, String itemRefId);
}
