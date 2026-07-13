import 'package:equatable/equatable.dart';

class BudgetItemEntity extends Equatable {
  final String id;
  final String tripId;
  final String? dayId;
  final String category;
  final String? description;
  final double amountUsd;
  final bool isEstimated;

  const BudgetItemEntity({
    required this.id,
    required this.tripId,
    this.dayId,
    required this.category,
    this.description,
    required this.amountUsd,
    required this.isEstimated,
  });

  @override
  List<Object?> get props =>
      [id, tripId, category, amountUsd, isEstimated];
}

class BudgetBreakdown extends Equatable {
  final double accommodation;
  final double food;
  final double transport;
  final double activities;
  final double shopping;
  final double other;

  const BudgetBreakdown({
    this.accommodation = 0,
    this.food = 0,
    this.transport = 0,
    this.activities = 0,
    this.shopping = 0,
    this.other = 0,
  });

  double get total =>
      accommodation + food + transport + activities + shopping + other;

  double percentOf(double value) =>
      total == 0 ? 0 : (value / total * 100);

  @override
  List<Object?> get props =>
      [accommodation, food, transport, activities, shopping, other];
}
