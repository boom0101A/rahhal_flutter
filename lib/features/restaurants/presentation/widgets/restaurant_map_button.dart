import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/map_launcher_service.dart';
import '../../../../core/utils/haptics.dart';
import '../../domain/entities/restaurant_entity.dart';

/// "Open in Google Maps" action for a restaurant, used where the Restaurants
/// tab's own inline link isn't available — currently Favorites and the
/// restaurant details sheet. Prefers the Google Places ID (exact venue) and
/// falls back to coordinates, matching the Restaurants tab's behaviour.
class RestaurantMapButton extends StatelessWidget {
  final RestaurantEntity restaurant;

  /// Renders a full-width filled button (details sheet) instead of the compact
  /// inline chip used inside list cards.
  final bool expanded;

  const RestaurantMapButton({
    super.key,
    required this.restaurant,
    this.expanded = false,
  });

  Future<void> _open(BuildContext context) async {
    Haptics.tap();
    final messenger = ScaffoldMessenger.of(context);
    final failureMessage = AppStrings.of(context).mapsOpenFailed;

    final launched = await MapLauncherService.openInGoogleMaps(
      placeName: restaurant.nameEn?.isNotEmpty == true
          ? restaurant.nameEn!
          : restaurant.name,
      lat: restaurant.latitude,
      lon: restaurant.longitude,
      placeId: restaurant.placeId,
    );

    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nothing reliable to point at — don't offer a broken map link.
    if (!restaurant.hasLocation) return const SizedBox.shrink();

    final strings = AppStrings.of(context);

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(Icons.map_rounded, size: 18),
          label: Text(strings.openInMaps),
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.accentTurquoise, size: 15),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  strings.openInMaps,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accentTurquoise,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.accentTurquoise,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.open_in_new_rounded,
                  color: AppColors.accentTurquoise, size: 12),
            ],
          ),
        ),
      ),
    );
  }
}
