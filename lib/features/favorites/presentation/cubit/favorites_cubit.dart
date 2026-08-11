import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/favorite_item.dart';
import '../../domain/repositories/favorites_repository.dart';

part 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesRepository _repository;

  FavoritesCubit({required FavoritesRepository repository})
      : _repository = repository,
        super(const FavoritesLoading());

  Future<void> loadFavorites() async {
    final result = await _repository.getFavorites();
    if (isClosed) return;
    result.fold(
      (failure) => emit(FavoritesError(failure.message)),
      (items) {
        final keys = items.map((i) => '${i.favorite.itemType}:${i.favorite.itemRefId}').toSet();
        emit(FavoritesLoaded(items: items, favoritedKeys: keys));
      },
    );
  }

  Future<void> toggleFavorite(
    String itemType,
    String itemRefId, {
    required String tripId,
    String? destinationName,
    String? notes,
  }) async {
    final current = state;
    final String key = '$itemType:$itemRefId';

    // Optimistic UI updates if already loaded
    if (current is FavoritesLoaded) {
      final isFav = current.favoritedKeys.contains(key);
      final updatedKeys = Set<String>.from(current.favoritedKeys);
      
      List<FavoriteItem> updatedItems = List.from(current.items);
      if (isFav) {
        updatedKeys.remove(key);
        updatedItems.removeWhere((i) => i.favorite.itemType == itemType && i.favorite.itemRefId == itemRefId);
      } else {
        updatedKeys.add(key);
      }
      emit(FavoritesLoaded(items: updatedItems, favoritedKeys: updatedKeys));
    }

    final result = await _repository.toggleFavorite(
      itemType,
      itemRefId,
      tripId: tripId,
      destinationName: destinationName,
      notes: notes,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        // Was a bare emit(FavoritesError(...)) — replaced the whole list with
        // a full-screen error for one failed toggle. loadFavorites() right
        // after is what actually rolls back the optimistic update above; the
        // error is now surfaced without destroying the list in between.
        _emitActionError(failure.message);
        loadFavorites();
      },
      (_) => loadFavorites(),
    );
  }

  bool isKeyFavorite(String itemType, String itemRefId) {
    final current = state;
    if (current is FavoritesLoaded) {
      return current.favoritedKeys.contains('$itemType:$itemRefId');
    }
    return false;
  }

  Future<void> updateNotes(
    String itemType,
    String itemRefId,
    String? notes,
  ) async {
    final result = await _repository.updateNotes(itemType, itemRefId, notes);
    if (isClosed) return;
    result.fold(
      (failure) => _emitActionError(failure.message),
      (_) => loadFavorites(),
    );
  }

  /// Keeps whatever's already on screen instead of replacing it with a
  /// full-screen error — mirrors BudgetCubit._emitActionError. Only a
  /// failure during the initial loadFavorites() (nothing loaded yet to
  /// preserve) falls back to FavoritesError.
  void _emitActionError(String message) {
    final current = state;
    emit(current is FavoritesLoaded
        ? current.withError(message)
        : FavoritesError(message));
  }

  /// Called by the UI right after it shows the action-error snackbar, so a
  /// later failure with the same message still triggers a fresh notice.
  void clearActionError() {
    final current = state;
    if (current is FavoritesLoaded && current.actionError != null) {
      emit(current.clearError());
    }
  }
}
