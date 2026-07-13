import '../../domain/entities/packing_item_entity.dart';

class PackingItemMapper {
  static PackingItemEntity fromMap(Map<String, dynamic> m) => PackingItemEntity(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        itemName: m['item_name'] as String,
        category: m['category'] as String? ?? 'other',
        isPacked: (m['is_packed'] as int? ?? 0) == 1,
        quantity: m['quantity'] as int? ?? 1,
        isAiSuggested: (m['is_ai_suggested'] as int? ?? 0) == 1,
      );

  static Map<String, dynamic> toMap(PackingItemEntity item) => {
        'id': item.id,
        'trip_id': item.tripId,
        'item_name': item.itemName,
        'category': item.category,
        'is_packed': item.isPacked ? 1 : 0,
        'quantity': item.quantity,
        'is_ai_suggested': item.isAiSuggested ? 1 : 0,
      };
}
