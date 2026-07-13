# ملف كود Dart: lib\features\budget\presentation\cubit\budget_state.dart

```dart
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

  const BudgetLoaded({required this.items, required this.breakdown});

  @override
  List<Object?> get props => [items, breakdown];
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);
  @override
  List<Object?> get props => [message];
}

```
