import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/category_ui.dart';
import '../../../../core/utils/localized_prose.dart';

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

  /// English copy of [address], filled in on demand like the other prose.
  final String? addressEn;
  final double costUsd;
  final String? aiTip;

  /// English copy of [aiTip], filled in on demand — see [localizedProse].
  final String? aiTipEn;
  final String? imageUrl;
  final bool bookingRequired;
  final String? bookingUrl;
  final String? placeId;
  final bool isVisited;

  /// English `weekdayDescriptions`, " • "-joined — the format
  /// `closingTimeFor` (core/utils/opening_hours.dart) parses. Only populated
  /// for stops verified against Google Places; null for trips generated
  /// before this field existed, or for a stop Places couldn't verify at all.
  final String? openingHoursEn;

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
    this.addressEn,
    required this.costUsd,
    this.aiTip,
    this.aiTipEn,
    this.imageUrl,
    required this.bookingRequired,
    this.bookingUrl,
    this.placeId,
    this.isVisited = false,
    this.openingHoursEn,
  });

  StopEntity copyWith({bool? isVisited}) => StopEntity(
        id: id,
        dayId: dayId,
        tripId: tripId,
        orderIndex: orderIndex,
        name: name,
        nameEn: nameEn,
        category: category,
        timeOfDay: timeOfDay,
        startTime: startTime,
        durationMinutes: durationMinutes,
        latitude: latitude,
        longitude: longitude,
        address: address,
        addressEn: addressEn,
        costUsd: costUsd,
        aiTip: aiTip,
        aiTipEn: aiTipEn,
        imageUrl: imageUrl,
        bookingRequired: bookingRequired,
        bookingUrl: bookingUrl,
        placeId: placeId,
        isVisited: isVisited ?? this.isVisited,
        openingHoursEn: openingHoursEn,
      );

  bool get hasValidLocation =>
      latitude.abs() > 0.001 && longitude.abs() > 0.001;

  String get categoryEmoji => stopCategoryEmoji(category);

  /// Empty when we have no real photo — see [RestaurantEntity.displayImageUrl].
  String get displayImageUrl => imageUrl?.trim() ?? '';

  /// The stop-level AI tip in the app current language.
  String? displayAiTip(BuildContext context) =>
      localizedProse(context, aiTip, aiTipEn);

  String displayName(BuildContext context) {
    final lang = AppStrings.of(context).languageCode;
    if (lang == 'en' && nameEn != null && nameEn!.isNotEmpty) {
      return nameEn!;
    }
    return name;
  }

  /// The address in the app's current language. Display only — the Maps and
  /// ride-hailing deep links deliberately keep using the raw [address].
  String? displayAddress(BuildContext context) =>
      localizedProse(context, address, addressEn);

  // The translatable fields have to be in here, or a stop that just gained its
  // English tip/name/address compares EQUAL to its old self and the cubit's
  // emit() is dropped as a no-op — leaving Arabic on screen despite the
  // database already holding the English text.
  @override
  List<Object?> get props => [
        id, dayId, tripId, orderIndex, name, nameEn, category, timeOfDay,
        latitude, longitude, address, addressEn, costUsd, aiTip, aiTipEn,
        bookingRequired, isVisited,
      ];
}
