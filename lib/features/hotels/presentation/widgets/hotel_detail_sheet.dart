import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/services/map_launcher_service.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../shared/widgets/cached_hero_image.dart';
import '../../domain/entities/hotel_entity.dart';

/// Professional bottom sheet with a hotel's full details plus an "open in
/// Google Maps" action (and a call button when a phone number is available).
/// Mirrors [RestaurantDetailSheet] so both tabs feel consistent.
class HotelDetailSheet extends StatelessWidget {
  final HotelEntity hotel;

  const HotelDetailSheet({super.key, required this.hotel});

  static Future<void> show(BuildContext context, HotelEntity hotel) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HotelDetailSheet(hotel: hotel),
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
                  url: hotel.displayImageUrl,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholderEmoji: '🏨',
                ),
              ),
              const SizedBox(height: 16),

              Text(
                hotel.displayName(context),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isDark ? AppColors.textPrimary : const Color(0xFF0D1B2A),
                ),
              ),

              if (hotel.hotelType != null && hotel.hotelType!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  hotel.hotelType!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hotel.hasRating)
                    _chip(
                      icon: Icons.star_rounded,
                      label: hotel.ratingLabel,
                      color: AppColors.accentAmber,
                    ),
                  if (hotel.pricePerNight > 0)
                    _chip(
                      icon: Icons.attach_money_rounded,
                      label:
                          '~\$${hotel.pricePerNight.toStringAsFixed(0)}/${strings.perNight}',
                      color: AppColors.textSecondary,
                    ),
                ],
              ),

              if (hotel.address != null && hotel.address!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _infoRow(Icons.place_rounded, hotel.address!),
              ],

              if (hotel.phone != null && hotel.phone!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _infoRow(Icons.call_rounded, hotel.phone!),
              ],

              if (hotel.aiDescription != null &&
                  hotel.aiDescription!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  hotel.aiDescription!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],

              const SizedBox(height: 24),

              // Primary action: open the exact listing in Google Maps.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Haptics.tap();
                    MapLauncherService.openInGoogleMaps(
                      placeName: hotel.nameEn?.isNotEmpty == true
                          ? hotel.nameEn!
                          : hotel.name,
                      lat: hotel.latitude,
                      lon: hotel.longitude,
                      placeId: hotel.placeId,
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: Text(strings.openInMaps),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTurquoise,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              if (hotel.phone != null && hotel.phone!.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Haptics.tap();
                      final uri = Uri.parse('tel:${hotel.phone}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: Text(strings.callAction),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentTurquoise,
                      side: const BorderSide(color: AppColors.accentTurquoise),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
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
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
