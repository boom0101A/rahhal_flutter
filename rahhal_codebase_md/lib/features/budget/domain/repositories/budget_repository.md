# ملف كود Dart: lib\features\budget\domain\repositories\budget_repository.dart

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/budget_item_entity.dart';

abstract class BudgetRepository {
  Future<Either<Failure, List<BudgetItemEntity>>> getBudgetItems(
      String tripId);
  Future<Either<Failure, BudgetBreakdown>> getBudgetBreakdown(
      String tripId);
}

```
