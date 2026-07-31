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

  /// Set when an add/delete action fails while this data is already on
  /// screen — a transient notice, not a reason to replace the loaded view.
  final String? actionError;

  const BudgetLoaded({
    required this.items,
    required this.breakdown,
    required this.expenses,
    required this.days,
    this.actionError,
  });

  BudgetLoaded withError(String message) => BudgetLoaded(
        items: items,
        breakdown: breakdown,
        expenses: expenses,
        days: days,
        actionError: message,
      );

  BudgetLoaded clearError() => BudgetLoaded(
        items: items,
        breakdown: breakdown,
        expenses: expenses,
        days: days,
      );

  @override
  List<Object?> get props => [items, breakdown, expenses, days, actionError];
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);
  @override
  List<Object?> get props => [message];
}
