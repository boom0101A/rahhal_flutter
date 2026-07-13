import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';

abstract class MapRepository {
  Future<Either<Failure, List<StopEntity>>> getStopsForTrip(String tripId);
  Future<Either<Failure, List<StopEntity>>> getStopsForDay(
      String dayId);
}
