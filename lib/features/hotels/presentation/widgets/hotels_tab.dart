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
import '../../domain/entities/hotel_entity.dart';

/// Lists the real, currently-operating hotels the server sourced for this trip's
/// destination (Google Places → OpenStreetMap fallback). Each card deep-links
/// into Google Maps at the hotel's exact location.
class HotelsTab extends StatelessWidget {
  final String tripId;

  const HotelsTab({super.key, required this.tripId});

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏨', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(strings.noHotelsFound,
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
              (e) => _HotelCard(hotel: e.value, index: e.key),
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

  const _HotelCard({required this.hotel, required this.index});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return GlassCard(
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
                Text(
                  hotel.displayName(context),
                  style: AppTextStyles.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hotel.hotelType != null && hotel.hotelType!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(hotel.hotelType!, style: AppTextStyles.bodySmall),
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
                if (hotel.aiDescription != null &&
                    hotel.aiDescription!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    hotel.aiDescription!,
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
      lat: hotel.latitude,
      lon: hotel.longitude,
      placeId: hotel.placeId,
    );

    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = hotel.address;
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
