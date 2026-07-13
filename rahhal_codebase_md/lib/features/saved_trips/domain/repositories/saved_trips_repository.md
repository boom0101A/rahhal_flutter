# ملف كود Dart: lib\features\saved_trips\domain\repositories\saved_trips_repository.dart

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../trip_planner/domain/entities/trip_entity.dart';

abstract class SavedTripsRepository {
  Future<Either<Failure, List<TripEntity>>> getAllTrips();
  Future<Either<Failure, void>> deleteTrip(String tripId);
  Future<Either<Failure, void>> updateTripStatus(String tripId, String status);
}

```
