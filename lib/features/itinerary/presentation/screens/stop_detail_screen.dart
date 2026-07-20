import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../../core/utils/haptics.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/cached_hero_image.dart';
import '../../../../core/services/map_launcher_service.dart';

class StopDetailScreen extends StatefulWidget {
  final String stopId;

  const StopDetailScreen({super.key, required this.stopId});

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  StopEntity? _stop;

  @override
  void initState() {
    super.initState();
    _loadStopDetails();
  }

  Future<void> _loadStopDetails() async {
    final result = await sl<ItineraryRepository>().getStopById(widget.stopId);
    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _errorMessage = failure.message;
          _isLoading = false;
        }),
        (stop) => setState(() {
          _stop = stop;
          _isLoading = false;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBgPrimary(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentAmber))
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContentView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(_errorMessage ?? AppStrings.of(context).errorGeneric, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: Text(AppStrings.of(context).back),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    final stop = _stop!;
    return Stack(
      children: [
        // Custom Scroll View for smooth scrolling behavior
        CustomScrollView(
          slivers: [
            // Sliver App Bar with Image
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppColors.adaptiveBgPrimary(context),
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
              actions: [
                if (_stop != null)
                  BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, state) {
                      final isFav = context.read<FavoritesCubit>().isKeyFavorite('stop', _stop!.id);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          color: isFav ? AppColors.error : Colors.white,
                        ),
                        tooltip: isFav
                            ? AppStrings.of(context).removeFromFavorites
                            : AppStrings.of(context).addToFavorites,
                        onPressed: () {
                          Haptics.toggle();
                          context.read<FavoritesCubit>().toggleFavorite(
                            'stop',
                            _stop!.id,
                            destinationName: _stop!.name,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFav
                                    ? AppStrings.of(context).favoriteRemoved
                                    : AppStrings.of(context).favoriteAdded,
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedHeroImage(
                      url: stop.displayImageUrl,
                      height: 240,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.adaptiveBgPrimary(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CategoryChip(category: stop.category),
                      PeriodBadge(period: stop.timeOfDay),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    stop.displayName(context),
                    style: AppTextStyles.headlineLarge,
                  ),
                  Builder(
                    builder: (context) {
                      final isEn = AppStrings.of(context).languageCode == 'en';
                      final secondary = isEn ? stop.name : stop.nameEn;
                      if (secondary != null && secondary.isNotEmpty && secondary != stop.displayName(context)) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            secondary,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.adaptiveTextSecondary(context)),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Stop statistics
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.schedule_rounded,
                          label: AppStrings.of(context).suggestedDuration,
                          value: AppStrings.of(context).formatDuration(stop.durationMinutes),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.attach_money_rounded,
                          label: AppStrings.of(context).estimatedCost,
                          value: stop.costUsd == 0 ? AppStrings.of(context).free : '~\$${stop.costUsd.toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Address
                  if (stop.address != null) ...[
                    Text(AppStrings.of(context).addressLabel, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      stop.address!,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // AI Tip
                  if (stop.aiTip != null) ...[
                    Text(AppStrings.of(context).aiSmartTip, style: AppTextStyles.titleMedium.copyWith(color: AppColors.accentAmber)),
                    const SizedBox(height: 8),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        stop.aiTip!,
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Location on Map Placeholder/Button
                  if (stop.hasValidLocation) ...[
                    Text(AppStrings.of(context).geoPosition, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(stop.latitude, stop.longitude),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none, // Non-interactive mini map
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.rahhalai.rahhal_flutter',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(stop.latitude, stop.longitude),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: AppColors.accentAmber,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 12),
                    // Action Buttons: Google Maps & Uber
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => MapLauncherService.openInGoogleMaps(
                              placeName: stop.displayName(context),
                              lat: stop.latitude,
                              lon: stop.longitude,
                            ),
                            icon: const Icon(Icons.directions_outlined, size: 18),
                            label: Text(
                              AppStrings.of(context).openInMaps,
                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.adaptiveBgPrimary(context)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentAmber,
                              foregroundColor: AppColors.adaptiveBgPrimary(context),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => MapLauncherService.openUberRide(
                              placeName: stop.displayName(context),
                              lat: stop.latitude,
                              lon: stop.longitude,
                            ),
                            icon: const Icon(Icons.local_taxi_rounded, size: 18, color: AppColors.accentAmber),
                            label: Text(
                              AppStrings.of(context).orderUber,
                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.accentAmber),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.accentAmber),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 100), // Spacing for bottom button
                ]),
              ),
            ),
          ],
        ),

        // Booking Action
        if (stop.bookingRequired)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: GradientButton(
              label: AppStrings.of(context).bookTicketsNow,
              icon: Icons.bookmark_added_rounded,
              onPressed: () => _openBookingUrl(stop.bookingUrl),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBgCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentAmber, size: 24),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.titleSmall),
        ],
      ),
    );
  }

  Future<void> _openBookingUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).bookingNoLink),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).bookingInvalidLink),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).bookingOpenFailed(url)),
            action: SnackBarAction(
              label: AppStrings.of(context).copyAction,
              onPressed: () => Clipboard.setData(ClipboardData(text: url)),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).linkOpenError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
