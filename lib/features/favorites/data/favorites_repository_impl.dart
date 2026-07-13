import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../../restaurants/domain/entities/restaurant_entity.dart';
import '../../trip_planner/domain/entities/stop_entity.dart';
import '../domain/entities/favorite_entity.dart';
import '../domain/entities/favorite_item.dart';
import '../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final DatabaseHelper _dbHelper;
  final AuthRepository _authRepository;

  FavoritesRepositoryImpl({
    required DatabaseHelper dbHelper,
    required AuthRepository authRepository,
  })  : _dbHelper = dbHelper,
        _authRepository = authRepository;

  @override
  Future<Either<Failure, List<FavoriteItem>>> getFavorites() async {
    try {
      final user = _authRepository.getCurrentUser();
      final userId = user?.uid;

      final rows = await _dbHelper.query(
        'favorites',
        where: userId != null ? 'user_id = ?' : null,
        whereArgs: userId != null ? [userId] : null,
        orderBy: 'created_at DESC',
      );

      final List<FavoriteItem> favoriteItems = [];
      for (final row in rows) {
        final favEntity = _favoriteFromMap(row);
        
        StopEntity? stop;
        RestaurantEntity? restaurant;

        if (favEntity.itemType == 'stop') {
          final stopRow = await _dbHelper.queryOne(
            'stops',
            where: 'id = ?',
            whereArgs: [favEntity.itemRefId],
          );
          if (stopRow != null) {
            stop = _stopFromMap(stopRow);
          }
        } else if (favEntity.itemType == 'restaurant') {
          final restRow = await _dbHelper.queryOne(
            'restaurants',
            where: 'id = ?',
            whereArgs: [favEntity.itemRefId],
          );
          if (restRow != null) {
            restaurant = _restaurantFromMap(restRow);
          }
        }

        // Only add if the referenced item still exists in database
        if (stop != null || restaurant != null) {
          favoriteItems.add(
            FavoriteItem(
              favorite: favEntity,
              stop: stop,
              restaurant: restaurant,
            ),
          );
        }
      }

      return Right(favoriteItems);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(
    String itemType,
    String itemRefId, {
    String? destinationName,
    String? notes,
  }) async {
    try {
      final user = _authRepository.getCurrentUser();
      final userId = user?.uid;

      final existing = await _dbHelper.query(
        'favorites',
        where: 'item_type = ? AND item_ref_id = ?',
        whereArgs: [itemType, itemRefId],
      );

      if (existing.isNotEmpty) {
        // Delete it
        await _dbHelper.delete(
          'favorites',
          where: 'item_type = ? AND item_ref_id = ?',
          whereArgs: [itemType, itemRefId],
        );
      } else {
        // Insert it
        await _dbHelper.insert('favorites', {
          'id': const Uuid().v4(),
          'user_id': userId,
          'item_type': itemType,
          'item_ref_id': itemRefId,
          'destination_name': destinationName,
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFavorite(
      String itemType, String itemRefId) async {
    try {
      final rows = await _dbHelper.query(
        'favorites',
        where: 'item_type = ? AND item_ref_id = ?',
        whereArgs: [itemType, itemRefId],
      );
      return Right(rows.isNotEmpty);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  FavoriteEntity _favoriteFromMap(Map<String, dynamic> m) => FavoriteEntity(
        id: m['id'] as String,
        userId: m['user_id'] as String?,
        itemType: m['item_type'] as String,
        itemRefId: m['item_ref_id'] as String,
        destinationName: m['destination_name'] as String?,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  StopEntity _stopFromMap(Map<String, dynamic> m) => StopEntity(
        id: m['id'] as String,
        dayId: m['day_id'] as String,
        tripId: m['trip_id'] as String,
        orderIndex: m['order_index'] as int? ?? 0,
        name: m['name'] as String,
        nameEn: m['name_en'] as String?,
        category: m['category'] as String? ?? 'other',
        timeOfDay: m['time_of_day'] as String? ?? 'morning',
        startTime: m['start_time'] as String?,
        durationMinutes: m['duration_minutes'] as int? ?? 60,
        latitude: (m['latitude'] as num? ?? 0).toDouble(),
        longitude: (m['longitude'] as num? ?? 0).toDouble(),
        address: m['address'] as String?,
        costUsd: (m['cost_usd'] as num? ?? 0).toDouble(),
        aiTip: m['ai_tip'] as String?,
        imageUrl: m['image_url'] as String?,
        bookingRequired: (m['booking_required'] as int? ?? 0) == 1,
        bookingUrl: m['booking_url'] as String?,
      );

  RestaurantEntity _restaurantFromMap(Map<String, dynamic> m) =>
      RestaurantEntity(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        dayId: m['day_id'] as String?,
        name: m['name'] as String,
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
