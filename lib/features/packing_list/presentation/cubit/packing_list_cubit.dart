import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/ai_service.dart';
import '../../domain/entities/packing_item_entity.dart';
import '../../domain/repositories/packing_repository.dart';

part 'packing_list_state.dart';

class PackingListCubit extends Cubit<PackingListState> {
  final PackingRepository _repository;
  final AITravelService _aiService;

  PackingListCubit({
    required PackingRepository repository,
    required AITravelService aiService,
  })  : _repository = repository,
        _aiService = aiService,
        super(const PackingListLoading());

  Future<void> loadPackingList(String tripId) async {
    emit(const PackingListLoading());
    final result = await _repository.getPackingItems(tripId);
    result.fold(
      (failure) => emit(PackingListError(failure.message)),
      (items) => emit(PackingListLoaded(items: items)),
    );
  }

  Future<void> toggleItemPacked(PackingItemEntity item) async {
    final current = state;
    if (current is! PackingListLoaded) return;

    final updatedItem = item.copyWith(isPacked: !item.isPacked);
    
    // Optimistic UI update
    final updatedList = current.items.map((i) => i.id == item.id ? updatedItem : i).toList();
    emit(current.copyWith(items: updatedList));

    final result = await _repository.updatePackingItem(updatedItem);
    result.fold(
      (failure) {
        // Rollback on failure
        emit(PackingListError(failure.message));
        loadPackingList(item.tripId);
      },
      (_) => null,
    );
  }

  Future<void> addItem(String tripId, String itemName, String category) async {
    final current = state;
    if (current is! PackingListLoaded) return;

    emit(current.copyWith(isActionLoading: true));

    final newItem = PackingItemEntity(
      id: const Uuid().v4(),
      tripId: tripId,
      itemName: itemName,
      category: category,
      isPacked: false,
      quantity: 1,
      isAiSuggested: false,
    );

    final result = await _repository.addPackingItem(newItem);
    result.fold(
      (failure) => emit(PackingListError(failure.message)),
      (_) {
        final updatedList = [...current.items, newItem];
        emit(PackingListLoaded(items: updatedList, isActionLoading: false));
      },
    );
  }

  Future<void> removeItem(String tripId, String itemId) async {
    final current = state;
    if (current is! PackingListLoaded) return;

    emit(current.copyWith(isActionLoading: true));

    final result = await _repository.deletePackingItem(itemId);
    result.fold(
      (failure) => emit(PackingListError(failure.message)),
      (_) {
        final updatedList = current.items.where((i) => i.id != itemId).toList();
        emit(PackingListLoaded(items: updatedList, isActionLoading: false));
      },
    );
  }

  Future<void> generateAIList({
    required String tripId,
    required String destination,
    required int durationDays,
    required List<String> travelStyles,
  }) async {
    final current = state;
    if (current is! PackingListLoaded) return;

    emit(current.copyWith(isActionLoading: true));

    try {
      final suggestions = await _aiService.generatePackingListAI(
        destination: destination,
        durationDays: durationDays,
        travelStyles: travelStyles,
      );

      final List<PackingItemEntity> generatedItems = [];
      for (final sug in suggestions) {
        final item = PackingItemEntity(
          id: const Uuid().v4(),
          tripId: tripId,
          itemName: sug['itemName'] as String,
          category: sug['category'] as String? ?? 'other',
          isPacked: false,
          quantity: 1,
          isAiSuggested: true,
        );
        generatedItems.add(item);
        await _repository.addPackingItem(item);
      }

      final updatedList = [...current.items, ...generatedItems];
      emit(PackingListLoaded(items: updatedList, isActionLoading: false));
    } catch (e) {
      emit(PackingListError('Failed to generate AI packing list: ${e.toString()}'));
    }
  }
}
