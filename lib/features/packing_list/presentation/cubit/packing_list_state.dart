part of 'packing_list_cubit.dart';

abstract class PackingListState extends Equatable {
  const PackingListState();

  @override
  List<Object?> get props => [];
}

class PackingListLoading extends PackingListState {
  const PackingListLoading();
}

class PackingListLoaded extends PackingListState {
  final List<PackingItemEntity> items;
  final bool isActionLoading;

  const PackingListLoaded({
    required this.items,
    this.isActionLoading = false,
  });

  PackingListLoaded copyWith({
    List<PackingItemEntity>? items,
    bool? isActionLoading,
  }) {
    return PackingListLoaded(
      items: items ?? this.items,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }

  @override
  List<Object?> get props => [items, isActionLoading];
}

class PackingListError extends PackingListState {
  final String message;

  const PackingListError(this.message);

  @override
  List<Object?> get props => [message];
}
