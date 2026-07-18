import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart' hide DatabaseException;
import '../../../../core/network/ai_service.dart';
import '../domain/entities/trip_entity.dart';
import '../domain/entities/stop_entity.dart';
import '../domain/repositories/trip_repository.dart';
import 'mappers/trip_mapper.dart';
import '../../../../core/network/cloud_sync_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/image_search_service.dart';

class TripRepositoryImpl implements TripRepository {
  final DatabaseHelper _dbHelper;
  final AITravelService _aiService;
  final CloudSyncService _syncService;
  final _uuid = const Uuid();

  TripRepositoryImpl({
    required DatabaseHelper dbHelper,
    required AITravelService aiService,
    required CloudSyncService syncService,
  })  : _dbHelper = dbHelper,
        _aiService = aiService,
        _syncService = syncService;

  // ─── Generate ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, TripEntity>> generateTripPlan({
    required String destination,
    required int durationDays,
    required String budgetTier,
    required List<String> travelStyles,
    required int travelersCount,
    DateTime? startDate,
  }) async {
    try {
      // Call AI service
      final response = await _aiService.generateTripPlan(
        destination: destination,
        durationDays: durationDays,
        budgetTier: budgetTier,
        travelStyles: travelStyles,
        travelersCount: travelersCount,
        startDate: startDate,
      );

      // Fetch hero image URL from search service
      String? heroImageUrl;
      try {
        heroImageUrl = await sl<ImageSearchService>().searchPhoto(response.heroImageQuery);
      } catch (e) {
        debugPrint('TripRepositoryImpl: Failed to fetch image search results: $e');
      }

      // Build TripEntity
      final now = DateTime.now();
      final tripId = _uuid.v4();
      final trip = TripEntity(
        id: tripId,
        destination: response.destination,
        destinationEn: response.destinationEn,
        countryCode: response.countryCode,
        startDate: startDate,
        endDate: startDate?.add(Duration(days: durationDays - 1)),
        durationDays: durationDays,
        budgetTier: budgetTier,
        budgetTotal: response.budgetTotalUsd,
        travelStyles: travelStyles,
        travelersCount: travelersCount,
        status: 'planned',
        heroImageUrl: heroImageUrl,
        aiSummary: response.aiSummary,
        travelTips: response.travelTips,
        bestTimeToVisit: response.bestTimeToVisit,
        currency: response.currency,
        timezone: response.timezone,
        isMockData: response.isMockData,
        createdAt: now,
        updatedAt: now,
      );

      // Persist to SQLite
      final saveResult = await saveTrip(trip: trip, planResponse: response);
      return saveResult.fold(
        (failure) => Left(failure),
        (_) => Right(trip),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AIException catch (e) {
      return Left(AIFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Save (insert entire trip plan into SQLite) ───────────────────────────

  @override
  Future<Either<Failure, void>> saveTrip({
    required TripEntity trip,
    required TripPlanResponse planResponse,
  }) async {
    try {
      // 1. Pre-fetch images for all stops and restaurants in parallel OUTSIDE the DB transaction
      final Map<String, String?> stopImageMap = {};
      final Map<String, String?> restaurantImageMap = {};
      final List<Future<void>> imageFetchTasks = [];

      // Tasks for stops
      for (final dayPlan in planResponse.days) {
        for (final stop in dayPlan.stops) {
          final query = (stop.imageSearchQuery != null && stop.imageSearchQuery!.isNotEmpty)
              ? stop.imageSearchQuery!
              : '${stop.nameEn.isNotEmpty ? stop.nameEn : stop.name} ${trip.destination}';
          final key = '${dayPlan.dayNumber}_${stop.orderIndex}_${stop.name}';
          imageFetchTasks.add(
            sl<ImageSearchService>().searchPhoto(query).then((url) {
              stopImageMap[key] = url;
            }).catchError((_) {
              stopImageMap[key] = null;
            }),
          );
        }

        final rec = dayPlan.recommendedRestaurant;
        if (rec != null) {
          final query = (rec.imageSearchQuery != null && rec.imageSearchQuery!.isNotEmpty)
              ? rec.imageSearchQuery!
              : '${rec.name} restaurant ${trip.destination}';
          final key = rec.name.trim().toLowerCase();
          imageFetchTasks.add(
            sl<ImageSearchService>().searchPhoto(query).then((url) {
              restaurantImageMap[key] = url;
            }).catchError((_) {
              restaurantImageMap[key] = null;
            }),
          );
        }
      }

      // Tasks for general restaurants
      for (final r in planResponse.allRestaurants) {
        final key = r.name.trim().toLowerCase();
        if (!restaurantImageMap.containsKey(key)) {
          final query = (r.imageSearchQuery != null && r.imageSearchQuery!.isNotEmpty)
              ? r.imageSearchQuery!
              : '${r.name} restaurant ${trip.destination}';
          imageFetchTasks.add(
            sl<ImageSearchService>().searchPhoto(query).then((url) {
              restaurantImageMap[key] = url;
            }).catchError((_) {
              restaurantImageMap[key] = null;
            }),
          );
        }
      }

      // Wait for all image searches to complete (timeout 5s max)
      try {
        await Future.wait(imageFetchTasks).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('⚠️ TripRepository: Photo pre-fetching timed out or partially failed: $e');
      }

      // 2. Perform fast DB operations inside transaction
      await _dbHelper.executeInTransaction((txn) async {
        // 1. Insert trip
        await txn.insert(
          'trips',
          TripMapper.toMap(trip),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final Map<String, Map<String, dynamic>> restaurantsToInsert = {};

        for (final dayPlan in planResponse.days) {
          final dayId = _uuid.v4();
          final dayDate = trip.startDate?.add(Duration(days: dayPlan.dateOffset));

          await txn.insert('days', {
            'id': dayId,
            'trip_id': trip.id,
            'day_number': dayPlan.dayNumber,
            'date': dayDate?.toIso8601String(),
            'theme': dayPlan.theme,
            'summary': dayPlan.summary,
          });

          // Insert Stops
          for (final stop in dayPlan.stops) {
            final hasValidCoords = stop.latitude.abs() > 0.001 && stop.longitude.abs() > 0.001;
            final key = '${dayPlan.dayNumber}_${stop.orderIndex}_${stop.name}';
            final fetchedUrl = stopImageMap[key];
            final fallbackSeed = (stop.name + trip.destination).hashCode.abs() % 1000;
            final stopImageUrl = (fetchedUrl != null && fetchedUrl.isNotEmpty)
                ? fetchedUrl
                : 'https://picsum.photos/seed/$fallbackSeed/800/600';

            await txn.insert('stops', {
              'id': _uuid.v4(),
              'day_id': dayId,
              'trip_id': trip.id,
              'order_index': stop.orderIndex,
              'name': stop.name,
              'name_en': stop.nameEn,
              'category': stop.category,
              'time_of_day': stop.timeOfDay,
              'start_time': stop.startTime,
              'duration_minutes': stop.durationMinutes,
              'latitude': hasValidCoords ? stop.latitude : null,
              'longitude': hasValidCoords ? stop.longitude : null,
              'address': stop.address,
              'cost_usd': stop.costUsd,
              'ai_tip': stop.aiTip,
              'booking_required': stop.bookingRequired ? 1 : 0,
              'booking_url': stop.bookingUrl,
              'image_url': stopImageUrl,
            });
          }

          // Insert Recommended Restaurant
          final rec = dayPlan.recommendedRestaurant;
          if (rec != null) {
            final key = rec.name.trim().toLowerCase();
            final fetchedUrl = restaurantImageMap[key];
            final fallbackSeed = (rec.name + trip.destination).hashCode.abs() % 1000;
            final recImageUrl = (fetchedUrl != null && fetchedUrl.isNotEmpty)
                ? fetchedUrl
                : 'https://picsum.photos/seed/$fallbackSeed/800/600';

            restaurantsToInsert[key] = {
              'id': _uuid.v4(),
              'trip_id': trip.id,
              'day_id': dayId,
              'name': rec.name,
              'name_en': rec.nameEn,
              'cuisine_type': rec.cuisineType,
              'halal_certified': rec.halalCertified ? 1 : 0,
              'rating': rec.rating,
              'price_per_person': rec.pricePerPersonUsd,
              'price_tier': _priceTier(rec.pricePerPersonUsd),
              'address': rec.address,
              'latitude': rec.latitude,
              'longitude': rec.longitude,
              'ai_description': rec.aiDescription,
              'is_recommended': 1,
              'image_url': recImageUrl,
            };
          }
        }

        // Insert General Restaurants
        for (final r in planResponse.allRestaurants) {
          final key = r.name.trim().toLowerCase();
          if (!restaurantsToInsert.containsKey(key)) {
            final fetchedUrl = restaurantImageMap[key];
            final fallbackSeed = (r.name + trip.destination).hashCode.abs() % 1000;
            final rImageUrl = (fetchedUrl != null && fetchedUrl.isNotEmpty)
                ? fetchedUrl
                : 'https://picsum.photos/seed/$fallbackSeed/800/600';

            restaurantsToInsert[key] = {
              'id': _uuid.v4(),
              'trip_id': trip.id,
              'day_id': null,
              'name': r.name,
              'name_en': r.nameEn,
              'cuisine_type': r.cuisineType,
              'halal_certified': r.halalCertified ? 1 : 0,
              'rating': r.rating,
              'price_per_person': r.pricePerPersonUsd,
              'price_tier': _priceTier(r.pricePerPersonUsd),
              'address': r.address,
              'latitude': r.latitude,
              'longitude': r.longitude,
              'ai_description': r.aiDescription,
              'is_recommended': 0,
              'image_url': rImageUrl,
            };
          }
        }

        for (final row in restaurantsToInsert.values) {
          await txn.insert('restaurants', row, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // Budget Items
        final breakdown = planResponse.budgetBreakdown;
        final budgetData = {
          'accommodation': breakdown.accommodationUsd,
          'food': breakdown.foodUsd,
          'transport': breakdown.transportUsd,
          'activities': breakdown.activitiesUsd,
          'shopping': breakdown.shoppingUsd,
        };
        for (final entry in budgetData.entries) {
          await txn.insert('budget_items', {
            'id': _uuid.v4(),
            'trip_id': trip.id,
            'category': entry.key,
            'description': entry.key,
            'amount_usd': entry.value,
            'is_estimated': 1,
          });
        }
      });

      unawaited(_syncService.syncTripToCloud(trip.id));

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.toString()));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<TripEntity>>> getAllTrips() async {
    try {
      final rows = await _dbHelper.query(
        'trips',
        orderBy: 'created_at DESC',
      );
      return Right(rows.map(TripMapper.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> getTripById(String tripId) async {
    try {
      final row = await _dbHelper.queryOne(
        'trips',
        where: 'id = ?',
        whereArgs: [tripId],
      );
      if (row == null) return const Left(DatabaseFailure('trip-not-found'));
      return Right(TripMapper.fromMap(row));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StopEntity>>> getStopsForTrip(
      String tripId) async {
    try {
      final rows = await _dbHelper.query(
        'stops',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'order_index ASC',
      );
      return Right(rows.map(_stopFromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StopEntity>>> getStopsForDay(String dayId) async {
    try {
      final rows = await _dbHelper.query(
        'stops',
        where: 'day_id = ?',
        whereArgs: [dayId],
        orderBy: 'order_index ASC',
      );
      return Right(rows.map(_stopFromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTripStatus(
      String tripId, String status) async {
    try {
      await _dbHelper.update(
        'trips',
        {'status': status, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [tripId],
      );
      // Trigger cloud sync in the background
      unawaited(_syncService.syncTripToCloud(tripId));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTrip(String tripId) async {
    try {
      await _dbHelper.delete('trips', where: 'id = ?', whereArgs: [tripId]);
      // Trigger cloud deletion in the background
      unawaited(_syncService.deleteTripFromCloud(tripId));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

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

  String _priceTier(double price) {
    if (price < 15) return 'budget';
    if (price < 40) return 'mid';
    return 'luxury';
  }

}
