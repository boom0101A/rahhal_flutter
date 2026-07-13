import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
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

  bool get hasValidLocation =>
      latitude.abs() > 0.001 && longitude.abs() > 0.001;

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

  String get displayImageUrl {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return imageUrl!;
    }
    final seed = (name + id).hashCode.abs() % 1000;
    return 'https://picsum.photos/seed/$seed/800/600';
  }

  String displayName(BuildContext context) {
    final lang = AppStrings.of(context).languageCode;
    if (lang == 'en' && nameEn != null && nameEn!.isNotEmpty) {
      return nameEn!;
    }
    return name;
  }



  @override
  List<Object?> get props => [
        id, dayId, tripId, orderIndex, name, category, timeOfDay,
        latitude, longitude, costUsd, bookingRequired,
      ];
}
