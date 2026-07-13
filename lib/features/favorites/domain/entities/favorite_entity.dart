import 'package:equatable/equatable.dart';

class FavoriteEntity extends Equatable {
  final String id;
  final String? userId;
  final String itemType; // 'stop' or 'restaurant'
  final String itemRefId;
  final String? destinationName;
  final String? notes;
  final DateTime createdAt;

  const FavoriteEntity({
    required this.id,
    this.userId,
    required this.itemType,
    required this.itemRefId,
    this.destinationName,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        itemType,
        itemRefId,
        destinationName,
        notes,
        createdAt,
      ];
}
