import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';

part 'trip_planner_state.dart';

class TripPlannerCubit extends Cubit<TripPlannerState> {
  final TripRepository _tripRepository;

  TripPlannerCubit({required TripRepository tripRepository})
      : _tripRepository = tripRepository,
        super(const TripPlannerInitial());

  Future<void> generateTripPlan({
    required String destination,
    required int durationDays,
    required String budgetTier,
    required List<String> travelStyles,
    required int travelersCount,
    DateTime? startDate,
  }) async {
    emit(const TripPlannerGenerating());

    final result = await _tripRepository.generateTripPlan(
      destination: destination,
      durationDays: durationDays,
      budgetTier: budgetTier,
      travelStyles: travelStyles,
      travelersCount: travelersCount,
      startDate: startDate,
    );

    result.fold(
      (failure) => emit(TripPlannerError(failure.message)),
      (trip) => emit(TripPlannerSuccess(trip)),
    );
  }

  void reset() => emit(const TripPlannerInitial());
}
