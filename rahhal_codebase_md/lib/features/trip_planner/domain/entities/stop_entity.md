# ملف كود Dart: lib\features\trip_planner\domain\entities\stop_entity.dart

```dart
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_strings.dart';

class StopEntity extends Equatable {
  final String id;
  final String dayId;
  final String tripId;
  final int orderIndex;
  final String name;
  final String? nameEn;
  final String category;
  final String timeOfDay; // morning | afternoon | evening
  final String? startTime;
  final int durationMinutes;
  final double latitude;
  final double longitude;
  final String? address;
  final double costUsd;
  final String? aiTip;
  final String? imageUrl;
  final bool bookingRequired;
  final String? bookingUrl;

  const StopEntity({
    required this.id,
    required this.dayId,
    required this.tripId,
    required this.orderIndex,
    required this.name,
    this.nameEn,
    required this.category,
    required this.timeOfDay,
    this.startTime,
    required this.durationMinutes,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.costUsd,
    this.aiTip,
    this.imageUrl,
    required this.bookingRequired,
    this.bookingUrl,
  });

  String get categoryEmoji => switch (category) {
        'museum' => '🏛️',
        'restaurant' => '🍽️',
        'park' => '🌿',
        'shopping' => '🛍️',
        'landmark' => '🗺️',
        'beach' => '🏖️',
        'mosque' => '🕌',
        'palace' => '🏰',
        'market' => '🏪',
        'viewpoint' => '🔭',
        _ => '📍',
      };

  String get categoryLabel => AppStrings.categoryName(category);

  String get timeOfDayLabel => switch (timeOfDay) {
        'morning' => AppStrings.periodMorning,
        'afternoon' => AppStrings.periodAfternoon,
        'evening' => AppStrings.periodEvening,
        _ => timeOfDay,
      };

  String get durationLabel => AppStrings.formatDuration(durationMinutes);

  String get costLabel =>
      costUsd == 0 ? AppStrings.costFree : '~\$${costUsd.toStringAsFixed(0)}';

  @override
  List<Object?> get props => [
        id, dayId, tripId, orderIndex, name, category, timeOfDay,
        latitude, longitude, costUsd, bookingRequired,
      ];
}

```
