import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/day_entity.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';

part 'itinerary_state.dart';

class ItineraryCubit extends Cubit<ItineraryState> {
  final ItineraryRepository _repository;

  ItineraryCubit({required ItineraryRepository repository})
      : _repository = repository,
        super(const ItineraryLoading());

  Future<void> loadItinerary(String tripId) async {
    emit(const ItineraryLoading());

    final daysResult = await _repository.getDaysForTrip(tripId);
    if (isClosed) return;
    // Either.fold() is synchronous and does not await a callback's returned
    // Future — the success branch below does real async work (a second
    // repository call), so without the `await` on fold() itself and async
    // returns from BOTH branches, loadItinerary() could return to its caller
    // before the days/stops it just kicked off had actually loaded. Any
    // caller doing `await cubit.loadItinerary(...)` then immediately reading
    // `state` (or calling another cubit method that requires
    // ItineraryLoaded) could see the wrong thing — including this cubit's
    // own reorderStops/selectDay, and any UI or test relying on the await.
    await daysResult.fold(
      (failure) async => emit(ItineraryError(failure.message)),
      (days) async {
        if (days.isEmpty) {
          emit(const ItineraryError('no-days-found'));
          return;
        }
        // Load stops for first day by default
        final stopsResult =
            await _repository.getStopsForDay(days.first.id);
        if (isClosed) return;
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

  /// Fetches the day's stops and emits ONE state carrying both the new
  /// index and the new stops together — no intermediate blanked/loading
  /// state. A local SQLite read is always fast, so the old two-emission
  /// version (blank stops + isLoadingStops:true, then real stops) just
  /// produced two abrupt jump-cuts in quick succession instead of one
  /// smooth transition; the UI now crossfades between the last-shown day's
  /// content and this new content directly.
  ///
  /// Deliberately no "same index, skip" guard here — reorderStops below
  /// calls this with the CURRENT index specifically to force a reload from
  /// SQLite after a drag-and-drop write. That guard belongs at the UI tap
  /// site instead.
  Future<void> selectDay(int dayIndex) async {
    final current = state;
    if (current is! ItineraryLoaded) return;

    final stopsResult =
        await _repository.getStopsForDay(current.days[dayIndex].id);
    if (isClosed) return;
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

    final result = await _repository.reorderStops(dayId, orderedStopIds);
    if (isClosed) return;
    // The Either used to be discarded entirely. selectDay() below reloads
    // from SQLite regardless, and on failure that pulls back the OLD order
    // (nothing was actually persisted) — this at least tells the user why
    // their drag-and-drop just reverted, instead of it looking like nothing
    // happened.
    result.fold(
      (failure) => emit(current.withError(failure.message)),
      (_) {},
    );
    await selectDay(current.selectedDayIndex);
  }

  /// Called by the UI right after it shows the action-error snackbar, so a
  /// later failure with the same message still triggers a fresh notice.
  void clearActionError() {
    final current = state;
    if (current is ItineraryLoaded && current.actionError != null) {
      emit(current.clearError());
    }
  }

  /// Toggle a stop's "visited" flag. Updates the UI immediately (optimistic)
  /// and rolls back only if the DB write fails, so ticking a stop feels instant.
  Future<void> toggleVisited(String stopId) async {
    final current = state;
    if (current is! ItineraryLoaded) return;

    final oldValue =
        current.selectedDayStops.firstWhere((s) => s.id == stopId).isVisited;
    final newValue = !oldValue;

    final updated = current.selectedDayStops
        .map((s) => s.id == stopId ? s.copyWith(isVisited: newValue) : s)
        .toList();

    emit(current.copyWith(selectedDayStops: updated));

    final result = await _repository.setStopVisited(stopId, newValue);
    if (isClosed) return;
    result.fold(
      // Revert only this stop, off whatever's current *now* — not the
      // snapshot from before the await — so a second toggleVisited() call
      // that raced in and already landed isn't wiped out too.
      (_) => _revertStopVisited(stopId, oldValue),
      (_) {},
    );
  }

  void _revertStopVisited(String stopId, bool oldValue) {
    final latest = state;
    if (latest is! ItineraryLoaded) return;
    final reverted = latest.selectedDayStops
        .map((s) => s.id == stopId ? s.copyWith(isVisited: oldValue) : s)
        .toList();
    emit(latest.copyWith(selectedDayStops: reverted));
  }
}
