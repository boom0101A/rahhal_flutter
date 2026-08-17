import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/services/map_launcher_service.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../../../../shared/widgets/cached_hero_image.dart';
import '../../../../../shared/widgets/shimmer_loader.dart';
import '../../../../../shared/widgets/app_error_widget.dart';
import '../cubit/hotels_cubit.dart';
import 'hotel_detail_sheet.dart';
import '../../domain/entities/hotel_entity.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';

/// Lists the real, currently-operating hotels the server sourced for this trip's
/// destination (Google Places → OpenStreetMap fallback). Each card deep-links
/// into Google Maps at the hotel's exact location.
class HotelsTab extends StatelessWidget {
  final String tripId;

  /// Trip country (ISO-2) — lets the booking section build a valid
  /// international WhatsApp number from a national phone number.
  final String? countryCode;

  /// The trip's chosen travel styles. Used only to pick which empty-state
  /// message to show — an empty list because "stay" wasn't selected gets a
  /// dedicated explanation instead of the generic "no hotels found" message.
  /// An older trip saved before this feature existed has no "stay" entry but
  /// DOES have real hotels, so this never hides rows that actually exist.
  final List<String>? travelStyles;

  const HotelsTab({
    super.key,
    required this.tripId,
    this.countryCode,
    this.travelStyles,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HotelsCubit, HotelsState>(
      builder: (context, state) {
        if (state is HotelsLoading) {
          return _buildSkeleton();
        }
        if (state is HotelsError) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () => context.read<HotelsCubit>().loadHotels(tripId),
          );
        }
        if (state is HotelsLoaded) {
          return _buildContent(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, HotelsLoaded state) {
    final strings = AppStrings.of(context);
    if (state.hotels.isEmpty) {
      final styleExplainsEmpty =
          travelStyles != null && !travelStyles!.contains('stay');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏨', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                  styleExplainsEmpty
                      ? strings.hotelsStyleNotSelected
                      : strings.noHotelsFound,
                  style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          '${state.hotels.length} ${strings.statsHotels}',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        ...state.hotels.asMap().entries.map(
              (e) => _HotelCard(
                  hotel: e.value, index: e.key, countryCode: countryCode),
            ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(6, (_) => const ShimmerRestaurantCard()),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final HotelEntity hotel;
  final int index;
  final String? countryCode;

  const _HotelCard(
      {required this.hotel, required this.index, this.countryCode});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return GestureDetector(
      onTap: () =>
          HotelDetailSheet.show(context, hotel, countryCode: countryCode),
      child: GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: CachedHeroImage(
                url: hotel.displayImageUrl,
                height: 72,
                fit: BoxFit.cover,
                placeholderEmoji: '🏨',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hotel.displayName(context),
                        style: AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<FavoritesCubit, FavoritesState>(
                      builder: (context, state) {
                        final isFav = context
                            .read<FavoritesCubit>()
                            .isKeyFavorite('hotel', hotel.id);
                        return IconButton(
                          icon: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            color: isFav
                                ? AppColors.error
                                : AppColors.adaptiveTextSecondary(context),
                            size: 20,
                          ),
                          tooltip: isFav
                              ? strings.removeFromFavorites
                              : strings.addToFavorites,
                          padding: EdgeInsets.zero,
                          // Icon stays 20px, but the tappable area is padded
                          // out to the WCAG/Material touch-target minimum —
                          // an empty BoxConstraints() collapsed the hit box
                          // down to the icon itself.
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          onPressed: () {
                            Haptics.toggle();
                            context.read<FavoritesCubit>().toggleFavorite(
                                  'hotel',
                                  hotel.id,
                                  tripId: hotel.tripId,
                                  destinationName: hotel.name,
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFav
                                      ? strings.favoriteRemoved
                                      : strings.favoriteAdded,
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                if (hotel.displayHotelType(context) != null &&
                    hotel.displayHotelType(context)!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(hotel.displayHotelType(context)!, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: 8),
                // Rating + price/night
                Row(
                  children: [
                    if (hotel.hasRating) ...[
                      const Icon(Icons.star_rounded,
                          color: AppColors.accentAmber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        hotel.ratingLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accentAmber,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (hotel.pricePerNight > 0) ...[
                      Icon(Icons.attach_money_rounded,
                          color: AppColors.adaptiveTextSecondary(context),
                          size: 14),
                      Text(
                        '~\$${hotel.pricePerNight.toStringAsFixed(0)}/${strings.perNight}',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ],
                ),
                if (hotel.displayAiDescription(context) != null &&
                    hotel.displayAiDescription(context)!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    hotel.displayAiDescription(context)!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.adaptiveTextSecondary(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Location → Google Maps
                if (hotel.hasLocation) ...[
                  const SizedBox(height: 8),
                  _MapLocationButton(hotel: hotel),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
        )
        .slideY(begin: 0.05, end: 0);
  }
}

/// Opens the hotel's real location in Google Maps. Prefers the Places ID
/// (exact listing) over coordinates, and shows the address inline so the user
/// can tell where it is without leaving the app.
class _MapLocationButton extends StatelessWidget {
  final HotelEntity hotel;

  const _MapLocationButton({required this.hotel});

  Future<void> _openMaps(BuildContext context) async {
    Haptics.tap();
    final messenger = ScaffoldMessenger.of(context);
    final failureMessage = AppStrings.of(context).mapsOpenFailed;

    final launched = await MapLauncherService.openInGoogleMaps(
      placeName:
          hotel.nameEn?.isNotEmpty == true ? hotel.nameEn! : hotel.name,
      city: hotel.address,
      lat: hotel.latitude,
      lon: hotel.longitude,
      placeId: hotel.placeId,
      persistTable: 'hotels',
      persistRowId: hotel.id,
    );

    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display only — _openMaps still queries with the raw address.
    final address = hotel.displayAddress(context);
    return InkWell(
      onTap: () => _openMaps(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_rounded,
                color: AppColors.accentTurquoise, size: 15),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                address != null && address.trim().isNotEmpty
                    ? address
                    : AppStrings.of(context).openInMaps,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accentTurquoise,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.accentTurquoise,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.open_in_new_rounded,
                color: AppColors.accentTurquoise, size: 12),
          ],
        ),
      ),
    );
  }
}
