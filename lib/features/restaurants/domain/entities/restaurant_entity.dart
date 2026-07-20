import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/constants/app_strings.dart';

class RestaurantEntity extends Equatable {
  final String id;
  final String tripId;
  final String? dayId;
  final String name;
  final String? nameEn;
  final String? cuisineType;
  final bool halalCertified;
  final double rating;
  final double pricePerPerson;
  final String priceTier;
  final String? address;
  final double latitude;
  final double longitude;
  final String? openingHours;
  final String? imageUrl;
  final String? aiDescription;
  final bool isRecommended;
  final String? placeId;
  final bool coordsVerified;

  const RestaurantEntity({
    required this.id,
    required this.tripId,
    this.dayId,
    required this.name,
    this.nameEn,
    this.cuisineType,
    required this.halalCertified,
    required this.rating,
    required this.pricePerPerson,
    required this.priceTier,
    this.address,
    required this.latitude,
    required this.longitude,
    this.openingHours,
    this.imageUrl,
    this.aiDescription,
    required this.isRecommended,
    this.placeId,
    this.coordsVerified = false,
  });

  String get ratingLabel => rating.toStringAsFixed(1);

  /// True when we have something good enough to point Google Maps at —
  /// either a Places ID or real coordinates.
  bool get hasLocation =>
      (placeId != null && placeId!.isNotEmpty) ||
      (latitude != 0.0 && longitude != 0.0);

  List<String> get tags {
    final result = <String>[];
    if (cuisineType != null && cuisineType!.isNotEmpty) {
      result.add(cuisineType!);
    }
    return result;
  }

  /// Empty when we have no real photo. Callers pass this to [CachedHeroImage],
  /// which renders its own placeholder tile — deliberately NOT a random stock
  /// photo, which would show an unrelated image as if it were this restaurant.
  String get displayImageUrl => imageUrl?.trim() ?? '';

  String displayName(BuildContext context) {
    final lang = AppStrings.of(context).languageCode;
    if (lang == 'en' && nameEn != null && nameEn!.isNotEmpty) {
      return nameEn!;
    }
    return name;
  }

  @override
  List<Object?> get props => [
        id, tripId, dayId, name, nameEn, cuisineType, halalCertified, rating,
        pricePerPerson, priceTier, address, latitude, longitude, openingHours,
        imageUrl, aiDescription, isRecommended, placeId, coordsVerified,
      ];
}
