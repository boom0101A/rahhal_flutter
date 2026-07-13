# ملف كود Dart: lib\features\budget\data\budget_repository_impl.dart

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../domain/entities/budget_item_entity.dart';
import '../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final DatabaseHelper _dbHelper;

  BudgetRepositoryImpl({required DatabaseHelper dbHelper})
      : _dbHelper = dbHelper;

  @override
  Future<Either<Failure, List<BudgetItemEntity>>> getBudgetItems(
      String tripId) async {
    try {
      final rows = await _dbHelper.query(
        'budget_items',
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );
      return Right(rows.map(_fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BudgetBreakdown>> getBudgetBreakdown(
      String tripId) async {
    try {
      final rows = await _dbHelper.query(
        'budget_items',
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );
      double accommodation = 0,
          food = 0,
          transport = 0,
          activities = 0,
          shopping = 0,
          other = 0;

      for (final row in rows) {
        final amount = (row['amount_usd'] as num? ?? 0).toDouble();
        switch (row['category'] as String?) {
          case 'accommodation':
            accommodation += amount;
          case 'food':
            food += amount;
          case 'transport':
            transport += amount;
          case 'activities':
            activities += amount;
          case 'shopping':
            shopping += amount;
          default:
            other += amount;
        }
      }

      return Right(BudgetBreakdown(
        accommodation: accommodation,
        food: food,
        transport: transport,
        activities: activities,
        shopping: shopping,
        other: other,
      ));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  BudgetItemEntity _fromMap(Map<String, dynamic> m) => BudgetItemEntity(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        dayId: m['day_id'] as String?,
        category: m['category'] as String? ?? 'other',
        description: m['description'] as String?,
        amountUsd: (m['amount_usd'] as num? ?? 0).toDouble(),
        isEstimated: (m['is_estimated'] as int? ?? 1) == 1,
      );
}

```
