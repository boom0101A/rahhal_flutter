import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/day_entity.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';

abstract class ItineraryRepository {
  Future<Either<Failure, List<DayEntity>>> getDaysForTrip(String tripId);
  Future<Either<Failure, List<StopEntity>>> getStopsForDay(String dayId);
  Future<Either<Failure, StopEntity>> getStopById(String stopId);
  Future<Either<Failure, void>> reorderStops(
      String dayId, List<String> orderedStopIds);
}
