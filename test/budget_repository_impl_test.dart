import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/database/database_helper.dart';
import 'package:rahhal_flutter/core/network/cloud_sync_service.dart';
import 'package:rahhal_flutter/features/budget/data/budget_repository_impl.dart';
import 'package:rahhal_flutter/features/budget/domain/entities/expense_entity.dart';

class _MockDb extends Mock implements DatabaseHelper {}

class _MockSync extends Mock implements CloudSyncService {}

void main() {
  group('BudgetRepositoryImpl.addExpense validation', () {
    late BudgetRepositoryImpl repository;

    setUp(() {
      repository = BudgetRepositoryImpl(
        dbHelper: _MockDb(),
        syncService: _MockSync(),
      );
    });

    test('a zero or negative amount returns a stable error CODE, not raw prose', () async {
      final expense = ExpenseEntity(
        id: 'e1',
        tripId: 't1',
        category: 'food',
        amount: 0,
        spentAt: DateTime(2026, 8, 17),
        createdAt: DateTime(2026, 8, 17),
      );

      final result = await repository.addExpense(expense);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'budget/invalid-amount'),
        (_) => fail('expected a Left'),
      );
    });
  });
}
