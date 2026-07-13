# ملف كود Dart: lib\features\trip_planner\data\trip_repository_impl.dart

```dart
import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/ai_service.dart';
import '../domain/entities/trip_entity.dart';
import '../domain/entities/stop_entity.dart';
import '../domain/repositories/trip_repository.dart';
import '../../../../core/network/cloud_sync_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/image_search_service.dart';
import '../../../../core/constants/app_strings.dart';

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
      await _dbHelper.executeInTransaction((txn) async {
        // 1. Insert trip
        await txn.insert(
          'trips',
          _tripToMap(trip),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 2. Insert days, stops, restaurants, budget_items
        for (final dayPlan in planResponse.days) {
          final dayId = _uuid.v4();
          final dayDate =
              trip.startDate?.add(Duration(days: dayPlan.dateOffset));

          await txn.insert('days', {
            'id': dayId,
            'trip_id': trip.id,
            'day_number': dayPlan.dayNumber,
            'date': dayDate?.toIso8601String(),
            'theme': dayPlan.theme,
            'summary': dayPlan.summary,
          });

          // Stops
          for (final stop in dayPlan.stops) {
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
              'latitude': stop.latitude,
              'longitude': stop.longitude,
              'address': stop.address,
              'cost_usd': stop.costUsd,
              'ai_tip': stop.aiTip,
              'booking_required': stop.bookingRequired ? 1 : 0,
              'booking_url': stop.bookingUrl,
            });
          }

          // Recommended restaurant for this day
          final rec = dayPlan.recommendedRestaurant;
          if (rec != null) {
            await txn.insert('restaurants', {
              'id': _uuid.v4(),
              'trip_id': trip.id,
              'day_id': dayId,
              'name': rec.name,
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
            });
          }
        }

        // 3. All restaurants (general pool)
        for (final r in planResponse.allRestaurants) {
          await txn.insert('restaurants', {
            'id': _uuid.v4(),
            'trip_id': trip.id,
            'name': r.name,
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
          });
        }

        // 4. Budget items
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
            'description': _budgetCategoryLabel(entry.key),
            'amount_usd': entry.value,
            'is_estimated': 1,
          });
        }
      });

      // Trigger cloud sync in the background (fire-and-forget)
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
      return Right(rows.map(_tripFromMap).toList());
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
      if (row == null) return Left(DatabaseFailure(AppStrings.errorTripNotFound));
      return Right(_tripFromMap(row));
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

  // ─── Mappers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _tripToMap(TripEntity t) => {
        'id': t.id,
        'user_id': t.userId,
        'destination': t.destination,
        'country_code': t.countryCode,
        'start_date': t.startDate?.toIso8601String(),
        'end_date': t.endDate?.toIso8601String(),
        'duration_days': t.durationDays,
        'budget_tier': t.budgetTier,
        'budget_total': t.budgetTotal,
        'travel_styles': jsonEncode(t.travelStyles),
        'travelers_count': t.travelersCount,
        'status': t.status,
        'hero_image_url': t.heroImageUrl,
        'ai_summary': t.aiSummary,
        'travel_tips': jsonEncode(t.travelTips),
        'best_time_to_visit': t.bestTimeToVisit,
        'currency': t.currency,
        'timezone': t.timezone,
        'created_at': t.createdAt.toIso8601String(),
        'updated_at': t.updatedAt.toIso8601String(),
        'synced_at': t.syncedAt?.toIso8601String(),
      };

  TripEntity _tripFromMap(Map<String, dynamic> m) => TripEntity(
        id: m['id'] as String,
        userId: m['user_id'] as String?,
        destination: m['destination'] as String,
        countryCode: m['country_code'] as String?,
        startDate: m['start_date'] != null
            ? DateTime.tryParse(m['start_date'] as String)
            : null,
        endDate: m['end_date'] != null
            ? DateTime.tryParse(m['end_date'] as String)
            : null,
        durationDays: m['duration_days'] as int? ?? 1,
        budgetTier: m['budget_tier'] as String? ?? 'mid',
        budgetTotal: (m['budget_total'] as num? ?? 0).toDouble(),
        travelStyles: _decodeList(m['travel_styles'] as String?),
        travelersCount: m['travelers_count'] as int? ?? 1,
        status: m['status'] as String? ?? 'planned',
        heroImageUrl: m['hero_image_url'] as String?,
        aiSummary: m['ai_summary'] as String?,
        travelTips: _decodeList(m['travel_tips'] as String?),
        bestTimeToVisit: m['best_time_to_visit'] as String?,
        currency: m['currency'] as String? ?? 'USD',
        timezone: m['timezone'] as String? ?? 'UTC',
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        syncedAt: m['synced_at'] != null
            ? DateTime.tryParse(m['synced_at'] as String)
            : null,
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

  List<String> _decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  String _priceTier(double price) {
    if (price < 15) return 'budget';
    if (price < 40) return 'mid';
    return 'luxury';
  }

  String _budgetCategoryLabel(String category) => AppStrings.budgetItemCategory(category);
}

```
