# ملف كود Dart: lib\features\restaurants\domain\repositories\restaurant_repository.dart

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/restaurant_entity.dart';

abstract class RestaurantRepository {
  Future<Either<Failure, List<RestaurantEntity>>> getRestaurantsForTrip(
      String tripId);
  Future<Either<Failure, RestaurantEntity>> getRestaurantById(String id);
}

```
