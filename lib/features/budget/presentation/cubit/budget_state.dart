part of 'budget_cubit.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();
  @override
  List<Object?> get props => [];
}

class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

class BudgetLoaded extends BudgetState {
  final List<BudgetItemEntity> items;
  final BudgetBreakdown breakdown;
  final List<ExpenseEntity> expenses;
  final List<DayEntity> days;

  const BudgetLoaded({
    required this.items,
    required this.breakdown,
    required this.expenses,
    required this.days,
  });

  @override
  List<Object?> get props => [items, breakdown, expenses, days];
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);
  @override
  List<Object?> get props => [message];
}
