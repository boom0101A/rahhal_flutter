import '../../domain/entities/expense_entity.dart';

class ExpenseMapper {
  static ExpenseEntity fromMap(Map<String, dynamic> m) => ExpenseEntity(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        dayId: m['day_id'] as String?,
        category: m['category'] as String? ?? 'other',
        description: m['description'] as String?,
        amount: (m['amount'] as num? ?? 0).toDouble(),
        currency: m['currency'] as String? ?? 'USD',
        receiptImagePath: m['receipt_image_path'] as String?,
        spentAt: DateTime.parse(m['spent_at'] as String),
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  static Map<String, dynamic> toMap(ExpenseEntity e) => {
        'id': e.id,
        'trip_id': e.tripId,
        'day_id': e.dayId,
        'category': e.category,
        'description': e.description,
        'amount': e.amount,
        'currency': e.currency,
        'receipt_image_path': e.receiptImagePath,
        'spent_at': e.spentAt.toIso8601String(),
        'created_at': e.createdAt.toIso8601String(),
      };
}
