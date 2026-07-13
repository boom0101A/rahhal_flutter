import 'package:equatable/equatable.dart';

class PackingItemEntity extends Equatable {
  final String id;
  final String tripId;
  final String itemName;
  final String category;
  final bool isPacked;
  final int quantity;
  final bool isAiSuggested;

  const PackingItemEntity({
    required this.id,
    required this.tripId,
    required this.itemName,
    this.category = 'other',
    this.isPacked = false,
    this.quantity = 1,
    this.isAiSuggested = false,
  });

  PackingItemEntity copyWith({
    String? id,
    String? tripId,
    String? itemName,
    String? category,
    bool? isPacked,
    int? quantity,
    bool? isAiSuggested,
  }) {
    return PackingItemEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      isPacked: isPacked ?? this.isPacked,
      quantity: quantity ?? this.quantity,
      isAiSuggested: isAiSuggested ?? this.isAiSuggested,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        itemName,
        category,
        isPacked,
        quantity,
        isAiSuggested,
      ];
}
