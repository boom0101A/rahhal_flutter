import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/favorite_item.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../../../core/services/analytics_service.dart';

part 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesRepository _repository;
  final AnalyticsService _analytics;

  // Guards toggleFavorite against a rapid double-tap on the same item: the
  // repository does a read-then-write with no DB-level uniqueness, so two
  // concurrent calls for the same key can both see "not favorited yet" and
  // each insert their own row, leaving the item duplicated in the list.
  final Set<String> _pendingToggles = {};

  FavoritesCubit({required FavoritesRepository repository, required AnalyticsService analytics})
      : _repository = repository,
        _analytics = analytics,
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
    final String key = '$itemType:$itemRefId';
    // A second tap on the same item while the first is still in flight is
    // ignored outright, rather than racing the repository's read-then-write.
    if (_pendingToggles.contains(key)) return;
    _pendingToggles.add(key);
    try {
      final current = state;
      final bool wasFavorited = current is FavoritesLoaded && current.favoritedKeys.contains(key);

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
        (_) {
          _analytics.logFavoriteToggle(
            itemType: itemType,
            itemId: itemRefId,
            isFavorited: !wasFavorited,
          );
          loadFavorites();
        },
      );
    } finally {
      _pendingToggles.remove(key);
    }
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
