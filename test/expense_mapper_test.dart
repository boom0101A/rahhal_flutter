import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/features/budget/data/mappers/expense_mapper.dart';
import 'package:rahhal_flutter/features/budget/domain/entities/expense_entity.dart';

void main() {
  group('ExpenseMapper receiptImagePath round-trip', () {
    test('toMap writes receipt_image_path, fromMap reads it back', () {
      final expense = ExpenseEntity(
        id: 'exp-1',
        tripId: 'trip-1',
        dayId: 'day-1',
        category: 'food',
        description: 'Lunch',
        amount: 12.5,
        spentAt: DateTime(2026, 8, 15, 12),
        createdAt: DateTime(2026, 8, 15, 12),
        receiptImagePath: '/data/app/trip_documents/abc123.jpg',
      );

      final map = ExpenseMapper.toMap(expense);
      expect(map['receipt_image_path'], '/data/app/trip_documents/abc123.jpg');

      final roundTripped = ExpenseMapper.fromMap(map);
      expect(roundTripped.receiptImagePath, '/data/app/trip_documents/abc123.jpg');
    });

    test('a missing receipt stays null through the round-trip', () {
      final expense = ExpenseEntity(
        id: 'exp-2',
        tripId: 'trip-1',
        category: 'transport',
        amount: 5,
        spentAt: DateTime(2026, 8, 15),
        createdAt: DateTime(2026, 8, 15),
      );

      final map = ExpenseMapper.toMap(expense);
      expect(map['receipt_image_path'], isNull);

      final roundTripped = ExpenseMapper.fromMap(map);
      expect(roundTripped.receiptImagePath, isNull);
    });
  });
}
