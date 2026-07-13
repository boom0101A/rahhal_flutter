# ملف كود Dart: lib\features\restaurants\domain\entities\restaurant_entity.dart

```dart
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_strings.dart';

class RestaurantEntity extends Equatable {
  final String id;
  final String tripId;
  final String? dayId;
  final String name;
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

  const RestaurantEntity({
    required this.id,
    required this.tripId,
    this.dayId,
    required this.name,
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
  });

  String get priceTierLabel => AppStrings.budgetTierName(priceTier);

  String get priceLabel =>
      '~\$${pricePerPerson.toStringAsFixed(0)}/${AppStrings.perPerson}';

  String get ratingLabel => rating.toStringAsFixed(1);

  List<String> get tags {
    final result = <String>[];
    if (halalCertified) result.add(AppStrings.restaurantHalal);
    if (cuisineType != null && cuisineType!.isNotEmpty) {
      result.add(cuisineType!);
    }
    return result;
  }

  @override
  List<Object?> get props => [
        id, tripId, dayId, name, cuisineType, halalCertified, rating,
        pricePerPerson, priceTier, isRecommended
      ];
}

```
