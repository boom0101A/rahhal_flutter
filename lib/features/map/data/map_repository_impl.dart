import 'package:dartz/dartz.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../trip_planner/domain/entities/stop_entity.dart';
import '../domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  final DatabaseHelper _dbHelper;

  MapRepositoryImpl({required DatabaseHelper dbHelper})
      : _dbHelper = dbHelper;

  @override
  Future<Either<Failure, List<StopEntity>>> getStopsForTrip(
      String tripId) async {
    try {
      final rows = await _dbHelper.query(
        'stops',
        where: 'trip_id = ? AND latitude IS NOT NULL AND longitude IS NOT NULL',
        whereArgs: [tripId],
        orderBy: 'order_index ASC',
      );
      return Right(rows.map(_fromMap).toList());
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
        where: 'day_id = ? AND latitude IS NOT NULL AND longitude IS NOT NULL',
        whereArgs: [dayId],
        orderBy: 'order_index ASC',
      );
      return Right(rows.map(_fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  StopEntity _fromMap(Map<String, dynamic> m) => StopEntity(
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
