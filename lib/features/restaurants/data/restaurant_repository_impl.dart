import 'package:dartz/dartz.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../domain/entities/restaurant_entity.dart';
import '../domain/repositories/restaurant_repository.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final DatabaseHelper _dbHelper;

  RestaurantRepositoryImpl({required DatabaseHelper dbHelper})
      : _dbHelper = dbHelper;

  @override
  Future<Either<Failure, List<RestaurantEntity>>> getRestaurantsForTrip(
      String tripId) async {
    try {
      final rows = await _dbHelper.query(
        'restaurants',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'is_recommended DESC, rating DESC',
      );
      return Right(rows.map(_fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RestaurantEntity>> getRestaurantById(
      String id) async {
    try {
      final row = await _dbHelper.queryOne(
          'restaurants', where: 'id = ?', whereArgs: [id]);
      if (row == null) {
        return const Left(DatabaseFailure('restaurant-not-found'));
      }
      return Right(_fromMap(row));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  RestaurantEntity _fromMap(Map<String, dynamic> m) => RestaurantEntity(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        dayId: m['day_id'] as String?,
        name: m['name'] as String,
        nameEn: m['name_en'] as String?,
        cuisineType: m['cuisine_type'] as String?,
        halalCertified: (m['halal_certified'] as int? ?? 0) == 1,
        rating: (m['rating'] as num? ?? 0).toDouble(),
        pricePerPerson: (m['price_per_person'] as num? ?? 0).toDouble(),
        priceTier: m['price_tier'] as String? ?? 'mid',
        address: m['address'] as String?,
        latitude: (m['latitude'] as num? ?? 0).toDouble(),
        longitude: (m['longitude'] as num? ?? 0).toDouble(),
        openingHours: m['opening_hours'] as String?,
        imageUrl: m['image_url'] as String?,
        aiDescription: m['ai_description'] as String?,
        isRecommended: (m['is_recommended'] as int? ?? 0) == 1,
      );
}
