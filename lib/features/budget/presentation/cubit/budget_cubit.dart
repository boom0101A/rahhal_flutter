import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../itinerary/domain/entities/day_entity.dart';
import '../../domain/entities/budget_item_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/budget_repository.dart';

part 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  final BudgetRepository _repository;

  BudgetCubit({required BudgetRepository repository})
      : _repository = repository,
        super(const BudgetLoading());

  Future<void> loadBudget(String tripId) async {
    emit(const BudgetLoading());

    final results = await Future.wait([
      _repository.getBudgetItems(tripId),
      _repository.getBudgetBreakdown(tripId),
      _repository.getExpenses(tripId),
      _repository.getTripDays(tripId),
    ]);

    final itemsResult = results[0] as Either<Failure, List<BudgetItemEntity>>;
    final breakdownResult = results[1] as Either<Failure, BudgetBreakdown>;
    final expensesResult = results[2] as Either<Failure, List<ExpenseEntity>>;
    final daysResult = results[3] as Either<Failure, List<DayEntity>>;

    itemsResult.fold(
      (failure) => emit(BudgetError(failure.message)),
      (items) {
        breakdownResult.fold(
          (failure) => emit(BudgetError(failure.message)),
          (breakdown) {
            expensesResult.fold(
              (failure) => emit(BudgetError(failure.message)),
              (expenses) {
                daysResult.fold(
                  (failure) => emit(BudgetError(failure.message)),
                  (days) => emit(BudgetLoaded(
                    items: items,
                    breakdown: breakdown,
                    expenses: expenses,
                    days: days,
                  )),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> addExpense(ExpenseEntity expense) async {
    final result = await _repository.addExpense(expense);
    result.fold(
      (failure) => emit(BudgetError(failure.message)),
      (_) => loadBudget(expense.tripId),
    );
  }

  Future<void> deleteExpense(String tripId, String expenseId) async {
    final result = await _repository.deleteExpense(expenseId);
    result.fold(
      (failure) => emit(BudgetError(failure.message)),
      (_) => loadBudget(tripId),
    );
  }
}
