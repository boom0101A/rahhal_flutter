import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/map_launcher_service.dart';
import '../../../../core/utils/haptics.dart';
import '../../domain/entities/restaurant_entity.dart';

/// "Open in Google Maps" action shown under a restaurant, mirroring the same
/// affordance the itinerary stops already have. Shared between the trip's
/// Restaurants tab and the Favorites screen so both behave identically.
class RestaurantMapButton extends StatelessWidget {
  final RestaurantEntity restaurant;

  /// Renders a wider, filled button (used on the detail sheet) instead of the
  /// compact inline chip used inside list cards.
  final bool expanded;

  const RestaurantMapButton({
    super.key,
    required this.restaurant,
    this.expanded = false,
  });

  Future<void> _open(BuildContext context) async {
    Haptics.tap();
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await MapLauncherService.openInGoogleMaps(
      placeName: restaurant.nameEn?.trim().isNotEmpty == true
          ? restaurant.nameEn!
          : restaurant.name,
      city: restaurant.address,
      lat: restaurant.latitude,
      lon: restaurant.longitude,
    );

    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.mapOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(Icons.map_rounded, size: 18),
          label: Text(strings.openInGoogleMaps),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentAmber,
            foregroundColor: AppColors.bgPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentAmber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: AppColors.accentAmber.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: AppColors.accentAmber),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  strings.restaurantLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accentAmber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
