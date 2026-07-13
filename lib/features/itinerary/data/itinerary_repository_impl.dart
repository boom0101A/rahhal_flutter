import 'package:dartz/dartz.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';

import '../domain/entities/day_entity.dart';
import '../domain/repositories/itinerary_repository.dart';
import '../../trip_planner/domain/entities/stop_entity.dart';

class ItineraryRepositoryImpl implements ItineraryRepository {
  final DatabaseHelper _dbHelper;

  ItineraryRepositoryImpl({required DatabaseHelper dbHelper})
      : _dbHelper = dbHelper;

  @override
  Future<Either<Failure, List<DayEntity>>> getDaysForTrip(
      String tripId) async {
    try {
      final rows = await _dbHelper.query(
        'days',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'day_number ASC',
      );
      return Right(rows.map(_dayFromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StopEntity>>> getStopsForDay(
      String dayId) async {
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
  Future<Either<Failure, StopEntity>> getStopById(String stopId) async {
    try {
      final row = await _dbHelper.queryOne(
        'stops',
        where: 'id = ?',
        whereArgs: [stopId],
      );
      if (row == null) {
        return const Left(DatabaseFailure('stop-not-found'));
      }
      return Right(_stopFromMap(row));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reorderStops(
      String dayId, List<String> orderedStopIds) async {
    try {
      await _dbHelper.executeInTransaction((txn) async {
        for (var i = 0; i < orderedStopIds.length; i++) {
          await txn.update(
            'stops',
            {'order_index': i},
            where: 'id = ? AND day_id = ?',
            whereArgs: [orderedStopIds[i], dayId],
          );
        }
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  DayEntity _dayFromMap(Map<String, dynamic> m) => DayEntity(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        dayNumber: m['day_number'] as int? ?? 1,
        date: m['date'] != null
            ? DateTime.tryParse(m['date'] as String)
            : null,
        theme: m['theme'] as String?,
        summary: m['summary'] as String?,
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
}
