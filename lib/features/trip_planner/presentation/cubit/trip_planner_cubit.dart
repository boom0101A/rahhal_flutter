import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../../../core/services/analytics_service.dart';

part 'trip_planner_state.dart';

class TripPlannerCubit extends Cubit<TripPlannerState> {
  final TripRepository _tripRepository;
  final AnalyticsService _analytics;

  TripPlannerCubit({required TripRepository tripRepository, required AnalyticsService analytics})
      : _tripRepository = tripRepository,
        _analytics = analytics,
        super(const TripPlannerInitial());

  Future<void> generateTripPlan({
    required String destination,
    required int durationDays,
    required String budgetTier,
    required List<String> travelStyles,
    required int travelersCount,
    DateTime? startDate,
    double? userLat,
    double? userLng,
    String? countryCode,
    double? targetBudgetUsd,
  }) async {
    emit(const TripPlannerGenerating());
    _analytics.logTripGenerationStart(
      destination: destination,
      durationDays: durationDays,
      budgetTier: budgetTier,
    );

    final result = await _tripRepository.generateTripPlan(
      destination: destination,
      durationDays: durationDays,
      budgetTier: budgetTier,
      travelStyles: travelStyles,
      travelersCount: travelersCount,
      startDate: startDate,
      userLat: userLat,
      userLng: userLng,
      countryCode: countryCode,
      targetBudgetUsd: targetBudgetUsd,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        emit(TripPlannerError(failure.message));
        _analytics.logTripGenerationFailure(destination: destination, reason: failure.message);
      },
      (trip) {
        emit(TripPlannerSuccess(trip));
        _analytics.logTripGenerationSuccess(destination: destination, durationDays: durationDays);
      },
    );
  }

  void reset() => emit(const TripPlannerInitial());
}
