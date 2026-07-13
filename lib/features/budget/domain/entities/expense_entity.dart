import 'package:equatable/equatable.dart';

class ExpenseEntity extends Equatable {
  final String id;
  final String tripId;
  final String? dayId;
  final String category;
  final String? description;
  final double amount;
  final String currency;
  final String? receiptImagePath;
  final DateTime spentAt;
  final DateTime createdAt;

  const ExpenseEntity({
    required this.id,
    required this.tripId,
    this.dayId,
    required this.category,
    this.description,
    required this.amount,
    this.currency = 'USD',
    this.receiptImagePath,
    required this.spentAt,
    required this.createdAt,
  });

  ExpenseEntity copyWith({
    String? id,
    String? tripId,
    String? dayId,
    String? category,
    String? description,
    double? amount,
    String? currency,
    String? receiptImagePath,
    DateTime? spentAt,
    DateTime? createdAt,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      dayId: dayId ?? this.dayId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      spentAt: spentAt ?? this.spentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        dayId,
        category,
        description,
        amount,
        currency,
        receiptImagePath,
        spentAt,
        createdAt,
      ];
}
