import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/services/analytics_service.dart';
import '../../../../../shared/widgets/booking_contact_section.dart';
import '../../../../../shared/widgets/cached_hero_image.dart';
import '../../../../../shared/widgets/report_issue_dialog.dart';
import '../../domain/entities/hotel_entity.dart';

/// Professional bottom sheet with a hotel's full details plus an "open in
/// Google Maps" action (and a call button when a phone number is available).
/// Mirrors [RestaurantDetailSheet] so both tabs feel consistent.
class HotelDetailSheet extends StatelessWidget {
  final HotelEntity hotel;

  /// Trip country (ISO-2) — used to build an international WhatsApp number.
  final String? countryCode;

  const HotelDetailSheet({super.key, required this.hotel, this.countryCode});

  static Future<void> show(BuildContext context, HotelEntity hotel,
      {String? countryCode}) {
    sl<AnalyticsService>().logDetailView(itemType: 'hotel', itemId: hotel.id);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          HotelDetailSheet(hotel: hotel, countryCode: countryCode),
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

              if (hotel.displayHotelType(context) != null &&
                  hotel.displayHotelType(context)!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  hotel.displayHotelType(context)!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.adaptiveTextSecondary(context)),
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
                      color: AppColors.adaptiveTextSecondary(context),
                    ),
                ],
              ),

              if (hotel.displayAddress(context) != null &&
                  hotel.displayAddress(context)!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _infoRow(
                    context, Icons.place_rounded, hotel.displayAddress(context)!),
              ],

              if (hotel.phone != null && hotel.phone!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _infoRow(context, Icons.call_rounded, hotel.phone!),
              ],

              if (hotel.displayAiDescription(context) != null &&
                  hotel.displayAiDescription(context)!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  hotel.displayAiDescription(context)!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.adaptiveTextSecondary(context)),
                ),
              ],

              const SizedBox(height: 24),

              BookingContactSection(
                placeName: hotel.name,
                placeNameEn: hotel.nameEn,
                phone: hotel.phone,
                address: hotel.address,
                latitude: hotel.latitude,
                longitude: hotel.longitude,
                placeId: hotel.placeId,
                countryCode: countryCode,
                onReport: () => showReportIssueDialog(
                  context,
                  sourceType: 'hotel',
                  tripId: hotel.tripId,
                  itemId: hotel.id,
                  itemName: hotel.name,
                  placeId: hotel.placeId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.adaptiveTextSecondary(context)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.adaptiveTextSecondary(context)),
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
