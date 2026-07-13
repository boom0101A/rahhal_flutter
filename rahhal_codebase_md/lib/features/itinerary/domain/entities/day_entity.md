# ملف كود Dart: lib\features\itinerary\domain\entities\day_entity.dart

```dart
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_strings.dart';

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

  String get label => '${AppStrings.planDayLabelPrefix} $dayNumber';

  String get shortDateLabel {
    if (date == null) return '';
    return '${date!.day} ${AppStrings.monthName(date!.month)}';
  }

  @override
  List<Object?> get props => [id, tripId, dayNumber, date, theme, summary];
}

```
