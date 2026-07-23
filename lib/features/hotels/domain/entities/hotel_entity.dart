import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/constants/app_strings.dart';

class HotelEntity extends Equatable {
  final String id;
  final String tripId;
  final String name;
  final String? nameEn;
  final String? hotelType;
  final double rating;
  final double pricePerNight;
  final String? address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? imageUrl;
  final String? aiDescription;
  final String? bookingUrl;
  final String? placeId;
  final bool coordsVerified;

  const HotelEntity({
    required this.id,
    required this.tripId,
    required this.name,
    this.nameEn,
    this.hotelType,
    required this.rating,
    required this.pricePerNight,
    this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.imageUrl,
    this.aiDescription,
    this.bookingUrl,
    this.placeId,
    this.coordsVerified = false,
  });

  String get ratingLabel => rating.toStringAsFixed(1);

  bool get hasRating => rating > 0;

  /// True when we have something good enough to point Google Maps at —
  /// either a Places ID or real coordinates.
  bool get hasLocation =>
      (placeId != null && placeId!.isNotEmpty) ||
      (latitude != 0.0 && longitude != 0.0);

  /// Empty when we have no real photo — the UI then renders a placeholder tile
  /// rather than an unrelated stock image captioned as this hotel.
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
        id, tripId, name, nameEn, hotelType, rating, pricePerNight, address,
        latitude, longitude, phone, imageUrl, aiDescription, bookingUrl,
        placeId, coordsVerified,
      ];
}
