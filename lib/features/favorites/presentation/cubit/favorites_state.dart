part of 'favorites_cubit.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteItem> items;
  final Set<String> favoritedKeys;

  /// Set when toggling a favorite or editing a note fails while the list is
  /// already on screen — a transient notice, not a reason to blank the whole
  /// list the way emitting FavoritesError used to.
  final String? actionError;

  const FavoritesLoaded({
    required this.items,
    required this.favoritedKeys,
    this.actionError,
  });

  FavoritesLoaded withError(String message) => FavoritesLoaded(
        items: items,
        favoritedKeys: favoritedKeys,
        actionError: message,
      );

  FavoritesLoaded clearError() => FavoritesLoaded(
        items: items,
        favoritedKeys: favoritedKeys,
      );

  @override
  List<Object?> get props => [items, favoritedKeys, actionError];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}
