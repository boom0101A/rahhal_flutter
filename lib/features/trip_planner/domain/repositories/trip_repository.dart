import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trip_entity.dart';
import '../entities/stop_entity.dart';
import '../../../../core/network/ai_service.dart';

abstract class TripRepository {
  /// Generate a new trip plan via AI and persist it locally.
  Future<Either<Failure, TripEntity>> generateTripPlan({
    required String destination,
    required int durationDays,
    required String budgetTier,
    required List<String> travelStyles,
    required int travelersCount,
    DateTime? startDate,
    double? userLat,
    double? userLng,
    String? countryCode,
  });

  /// Get all trips for the current user.
  Future<Either<Failure, List<TripEntity>>> getAllTrips();

  /// Get a single trip by ID.
  Future<Either<Failure, TripEntity>> getTripById(String tripId);

  /// Save a generated trip (insert or replace).
  Future<Either<Failure, void>> saveTrip({
    required TripEntity trip,
    required TripPlanResponse planResponse,
  });

  /// Update trip status (planned → active → completed).
  Future<Either<Failure, void>> updateTripStatus(
      String tripId, String status);

  /// Delete a trip and all its related data.
  Future<Either<Failure, void>> deleteTrip(String tripId);

  /// Get all stops for a trip.
  Future<Either<Failure, List<StopEntity>>> getStopsForTrip(String tripId);

  /// Get stops for a specific day.
  Future<Either<Failure, List<StopEntity>>> getStopsForDay(String dayId);
}
