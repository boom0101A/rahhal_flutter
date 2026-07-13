# ملف كود Dart: lib\features\saved_trips\data\saved_trips_repository_impl.dart

```dart
import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../domain/repositories/saved_trips_repository.dart';
import '../../trip_planner/domain/entities/trip_entity.dart';
import '../../../../core/network/cloud_sync_service.dart';

class SavedTripsRepositoryImpl implements SavedTripsRepository {
  final DatabaseHelper _dbHelper;
  final CloudSyncService _syncService;

  SavedTripsRepositoryImpl({
    required DatabaseHelper dbHelper,
    required CloudSyncService syncService,
  })  : _dbHelper = dbHelper,
        _syncService = syncService;

  @override
  Future<Either<Failure, List<TripEntity>>> getAllTrips() async {
    try {
      final rows = await _dbHelper.query(
        'trips',
        orderBy: 'created_at DESC',
      );
      return Right(rows.map(_fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTrip(String tripId) async {
    try {
      await _dbHelper.delete('trips', where: 'id = ?', whereArgs: [tripId]);
      unawaited(_syncService.deleteTripFromCloud(tripId));
      return const Right(null);
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
      unawaited(_syncService.syncTripToCloud(tripId));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  TripEntity _fromMap(Map<String, dynamic> m) => TripEntity(
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

  List<String> _decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}

```
