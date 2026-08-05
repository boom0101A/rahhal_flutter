import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../../restaurants/domain/entities/restaurant_entity.dart';
import '../../hotels/domain/entities/hotel_entity.dart';
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

  /// The `WHERE` fragment that restricts a query to the signed-in account's
  /// own rows.
  ///
  /// Every read and write goes through this. Writing the clause out at each
  /// call site is how the bug this fixes happened: the insert stamped
  /// `user_id`, but the lookups didn't filter on it, so on a shared device one
  /// account's heart-tap matched — and deleted — another account's row.
  ///
  /// Signed out has to be `IS NULL`, not `= ?` with a null argument: SQL
  /// equality against NULL is never true, so that would match nothing at all.
  ({String clause, List<Object?> args}) _ownerScope(String? userId) =>
      userId == null
          ? (clause: 'user_id IS NULL', args: const <Object?>[])
          : (clause: 'user_id = ?', args: <Object?>[userId]);

  @override
  Future<Either<Failure, List<FavoriteItem>>> getFavorites() async {
    try {
      final user = _authRepository.getCurrentUser();
      final scope = _ownerScope(user?.uid);

      final rows = await _dbHelper.query(
        'favorites',
        // Was `where: null` when signed out, which showed every account on the
        // device each other's favourites.
        where: scope.clause,
        whereArgs: scope.args,
        orderBy: 'created_at DESC',
      );

      final List<FavoriteItem> favoriteItems = [];
      final destinationCache = <String, String?>{};

      for (final row in rows) {
        final favEntity = _favoriteFromMap(row);

        StopEntity? stop;
        RestaurantEntity? restaurant;
        HotelEntity? hotel;
        String? tripId;

        if (favEntity.itemType == 'stop') {
          final stopRow = await _dbHelper.queryOne(
            'stops',
            where: 'id = ?',
            whereArgs: [favEntity.itemRefId],
          );
          if (stopRow != null) {
            stop = _stopFromMap(stopRow);
            tripId = stop.tripId;
          }
        } else if (favEntity.itemType == 'restaurant') {
          final restRow = await _dbHelper.queryOne(
            'restaurants',
            where: 'id = ?',
            whereArgs: [favEntity.itemRefId],
          );
          if (restRow != null) {
            restaurant = _restaurantFromMap(restRow);
            tripId = restaurant.tripId;
          }
        } else if (favEntity.itemType == 'hotel') {
          final hotelRow = await _dbHelper.queryOne(
            'hotels',
            where: 'id = ?',
            whereArgs: [favEntity.itemRefId],
          );
          if (hotelRow != null) {
            hotel = _hotelFromMap(hotelRow);
            tripId = hotel.tripId;
          }
        }

        // Only add if the referenced item still exists in database
        if (stop != null || restaurant != null || hotel != null) {
          String? tripDestination;
          if (tripId != null) {
            if (destinationCache.containsKey(tripId)) {
              tripDestination = destinationCache[tripId];
            } else {
              final tripRow = await _dbHelper.queryOne(
                'trips',
                where: 'id = ?',
                whereArgs: [tripId],
              );
              tripDestination = tripRow?['destination'] as String?;
              destinationCache[tripId] = tripDestination;
            }
          }

          favoriteItems.add(
            FavoriteItem(
              favorite: favEntity,
              stop: stop,
              restaurant: restaurant,
              hotel: hotel,
              tripDestination: tripDestination,
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
    required String tripId,
    String? destinationName,
    String? notes,
  }) async {
    try {
      final user = _authRepository.getCurrentUser();
      final userId = user?.uid;
      final scope = _ownerScope(userId);
      // One clause, used by both the lookup and the delete. If those two ever
      // disagreed, a tap would find nothing and then delete the wrong row.
      final where = 'item_type = ? AND item_ref_id = ? AND ${scope.clause}';
      final whereArgs = [itemType, itemRefId, ...scope.args];

      final existing = await _dbHelper.query(
        'favorites',
        where: where,
        whereArgs: whereArgs,
      );

      if (existing.isNotEmpty) {
        // Delete it
        await _dbHelper.delete(
          'favorites',
          where: where,
          whereArgs: whereArgs,
        );
      } else {
        // Insert it — trip_id lets the row cascade-delete along with the
        // trip instead of becoming a dead row once its stop/restaurant/hotel
        // is gone (see the v10 migration in database_helper.dart).
        await _dbHelper.insert('favorites', {
          'id': const Uuid().v4(),
          'user_id': userId,
          'trip_id': tripId,
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
      // No callers today — the UI asks FavoritesCubit.isKeyFavorite, which
      // reads the already-scoped list. Scoped anyway so the next caller
      // doesn't inherit the bug.
      final scope = _ownerScope(_authRepository.getCurrentUser()?.uid);
      final rows = await _dbHelper.query(
        'favorites',
        where: 'item_type = ? AND item_ref_id = ? AND ${scope.clause}',
        whereArgs: [itemType, itemRefId, ...scope.args],
      );
      return Right(rows.isNotEmpty);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateNotes(
    String itemType,
    String itemRefId,
    String? notes,
  ) async {
    try {
      final scope = _ownerScope(_authRepository.getCurrentUser()?.uid);
      await _dbHelper.update(
        'favorites',
        {'notes': notes},
        where: 'item_type = ? AND item_ref_id = ? AND ${scope.clause}',
        whereArgs: [itemType, itemRefId, ...scope.args],
      );
      return const Right(null);
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
        aiTipEn: m['ai_tip_en'] as String?,
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
        cuisineTypeEn: m['cuisine_type_en'] as String?,
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
        aiDescriptionEn: m['ai_description_en'] as String?,
        isRecommended: (m['is_recommended'] as int? ?? 0) == 1,
      );

  HotelEntity _hotelFromMap(Map<String, dynamic> m) => HotelEntity(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        name: m['name'] as String,
        nameEn: m['name_en'] as String?,
        hotelType: m['hotel_type'] as String?,
        hotelTypeEn: m['hotel_type_en'] as String?,
        rating: (m['rating'] as num? ?? 0).toDouble(),
        pricePerNight: (m['price_per_night'] as num? ?? 0).toDouble(),
        address: m['address'] as String?,
        latitude: (m['latitude'] as num? ?? 0).toDouble(),
        longitude: (m['longitude'] as num? ?? 0).toDouble(),
        phone: m['phone'] as String?,
        imageUrl: m['image_url'] as String?,
        aiDescription: m['ai_description'] as String?,
        aiDescriptionEn: m['ai_description_en'] as String?,
        bookingUrl: m['booking_url'] as String?,
        placeId: m['place_id'] as String?,
        coordsVerified: (m['coords_verified'] as int? ?? 0) == 1,
      );
}
