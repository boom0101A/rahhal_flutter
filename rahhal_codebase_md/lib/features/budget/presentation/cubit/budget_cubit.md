# ملف كود Dart: lib\features\budget\presentation\cubit\budget_cubit.dart

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/budget_item_entity.dart';
import '../../domain/repositories/budget_repository.dart';

part 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  final BudgetRepository _repository;

  BudgetCubit({required BudgetRepository repository})
      : _repository = repository,
        super(const BudgetLoading());

  Future<void> loadBudget(String tripId) async {
    emit(const BudgetLoading());

    final itemsResult = await _repository.getBudgetItems(tripId);
    final breakdownResult = await _repository.getBudgetBreakdown(tripId);

    itemsResult.fold(
      (failure) => emit(BudgetError(failure.message)),
      (items) {
        breakdownResult.fold(
          (failure) => emit(BudgetError(failure.message)),
          (breakdown) => emit(BudgetLoaded(
            items: items,
            breakdown: breakdown,
          )),
        );
      },
    );
  }
}

```
