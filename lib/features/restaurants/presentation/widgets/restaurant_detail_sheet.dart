import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../shared/widgets/booking_contact_section.dart';
import '../../../../shared/widgets/cached_hero_image.dart';
import '../../../../shared/widgets/report_issue_dialog.dart';
import '../../domain/entities/restaurant_entity.dart';

/// Bottom sheet with a restaurant's details plus an "open in Google Maps"
/// action. Used from Favorites (where there is no trip context to navigate
/// into) so a saved restaurant is still fully inspectable.
class RestaurantDetailSheet extends StatelessWidget {
  final RestaurantEntity restaurant;

  /// Trip country (ISO-2) — used to build an international WhatsApp number.
  final String? countryCode;

  const RestaurantDetailSheet(
      {super.key, required this.restaurant, this.countryCode});

  static Future<void> show(BuildContext context, RestaurantEntity restaurant,
      {String? countryCode}) {
    sl<AnalyticsService>().logDetailView(itemType: 'restaurant', itemId: restaurant.id);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RestaurantDetailSheet(
          restaurant: restaurant, countryCode: countryCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.adaptiveBgPrimary(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.adaptiveBorder(context),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedHeroImage(
                  url: restaurant.displayImageUrl,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                restaurant.displayName(context),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isDark ? AppColors.textPrimary : const Color(0xFF0D1B2A),
                ),
              ),

              if (restaurant.displayCuisineType(context) != null &&
                  restaurant.displayCuisineType(context)!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  restaurant.displayCuisineType(context)!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.adaptiveTextSecondary(context)),
                ),
              ],

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    icon: Icons.star_rounded,
                    label: restaurant.ratingLabel,
                    color: AppColors.accentAmber,
                  ),
                  _chip(
                    icon: Icons.attach_money_rounded,
                    label:
                        '~\$${restaurant.pricePerPerson.toStringAsFixed(0)}/${strings.perPerson}',
                    color: AppColors.adaptiveTextSecondary(context),
                  ),
                  if (restaurant.halalCertified)
                    _chip(
                      icon: Icons.verified_rounded,
                      label: strings.restaurantFilterHalal,
                      color: AppColors.success,
                    ),
                ],
              ),

              if (restaurant.address != null &&
                  restaurant.address!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_rounded,
                        size: 16, color: AppColors.adaptiveTextSecondary(context)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        restaurant.address!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.adaptiveTextSecondary(context)),
                      ),
                    ),
                  ],
                ),
              ],

              if (restaurant.openingHours != null &&
                  restaurant.openingHours!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: AppColors.adaptiveTextSecondary(context)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        restaurant.openingHours!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.adaptiveTextSecondary(context)),
                      ),
                    ),
                  ],
                ),
              ],

              if (restaurant.displayAiDescription(context) != null &&
                  restaurant.displayAiDescription(context)!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  restaurant.displayAiDescription(context)!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.adaptiveTextSecondary(context)),
                ),
              ],

              const SizedBox(height: 24),
              BookingContactSection(
                placeName: restaurant.name,
                placeNameEn: restaurant.nameEn,
                phone: restaurant.phone,
                address: restaurant.address,
                latitude: restaurant.latitude,
                longitude: restaurant.longitude,
                placeId: restaurant.placeId,
                countryCode: countryCode,
                onReport: () => showReportIssueDialog(
                  context,
                  sourceType: 'restaurant',
                  tripId: restaurant.tripId,
                  itemId: restaurant.id,
                  itemName: restaurant.name,
                  placeId: restaurant.placeId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
