import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../itinerary/domain/entities/day_entity.dart';
import '../entities/budget_item_entity.dart';
import '../entities/expense_entity.dart';

abstract class BudgetRepository {
  Future<Either<Failure, List<BudgetItemEntity>>> getBudgetItems(
      String tripId);
  Future<Either<Failure, BudgetBreakdown>> getBudgetBreakdown(
      String tripId);
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses(
      String tripId);
  Future<Either<Failure, void>> addExpense(
      ExpenseEntity expense);
  Future<Either<Failure, void>> deleteExpense(
      String expenseId);
  Future<Either<Failure, List<DayEntity>>> getTripDays(
      String tripId);
}
