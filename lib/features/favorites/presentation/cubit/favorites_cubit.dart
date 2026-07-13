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
      destinationName: destinationName,
      notes: notes,
    );

    result.fold(
      (failure) {
        emit(FavoritesError(failure.message));
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
}
