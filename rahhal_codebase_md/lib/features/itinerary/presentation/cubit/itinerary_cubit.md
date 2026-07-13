# ملف كود Dart: lib\features\itinerary\presentation\cubit\itinerary_cubit.dart

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/day_entity.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';
import '../../../../../core/constants/app_strings.dart';

part 'itinerary_state.dart';

class ItineraryCubit extends Cubit<ItineraryState> {
  final ItineraryRepository _repository;

  ItineraryCubit({required ItineraryRepository repository})
      : _repository = repository,
        super(const ItineraryLoading());

  Future<void> loadItinerary(String tripId) async {
    emit(const ItineraryLoading());

    final daysResult = await _repository.getDaysForTrip(tripId);
    daysResult.fold(
      (failure) => emit(ItineraryError(failure.message)),
      (days) async {
        if (days.isEmpty) {
          emit(ItineraryError(AppStrings.languageCode == 'ar'
              ? 'لا توجد أيام في هذه الرحلة'
              : 'No days found in this trip'));
          return;
        }
        // Load stops for first day by default
        final stopsResult =
            await _repository.getStopsForDay(days.first.id);
        stopsResult.fold(
          (failure) => emit(ItineraryError(failure.message)),
          (stops) => emit(ItineraryLoaded(
            days: days,
            selectedDayIndex: 0,
            selectedDayStops: stops,
          )),
        );
      },
    );
  }

  Future<void> selectDay(int dayIndex) async {
    final current = state;
    if (current is! ItineraryLoaded) return;

    emit(ItineraryLoaded(
      days: current.days,
      selectedDayIndex: dayIndex,
      selectedDayStops: const [],
      isLoadingStops: true,
    ));

    final stopsResult =
        await _repository.getStopsForDay(current.days[dayIndex].id);
    stopsResult.fold(
      (failure) => emit(ItineraryError(failure.message)),
      (stops) => emit(ItineraryLoaded(
        days: current.days,
        selectedDayIndex: dayIndex,
        selectedDayStops: stops,
      )),
    );
  }

  Future<void> reorderStops(
      String dayId, List<String> orderedStopIds) async {
    final current = state;
    if (current is! ItineraryLoaded) return;

    await _repository.reorderStops(dayId, orderedStopIds);
    await selectDay(current.selectedDayIndex);
  }
}

```
