import 'package:equatable/equatable.dart';

class DayEntity extends Equatable {
  final String id;
  final String tripId;
  final int dayNumber;
  final DateTime? date;
  final String? theme;
  final String? summary;

  const DayEntity({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    this.date,
    this.theme,
    this.summary,
  });



  @override
  List<Object?> get props => [id, tripId, dayNumber, date, theme, summary];
}
