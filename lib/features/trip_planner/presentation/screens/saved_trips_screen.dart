import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/cached_hero_image.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/haptics.dart';
import '../cubit/saved_trips_cubit.dart';
import '../../domain/entities/trip_entity.dart';

class SavedTripsScreen extends StatefulWidget {
  const SavedTripsScreen({super.key});

  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  bool _isLocating = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SavedTripsCubit>()..loadTrips(),
      child: Scaffold(
        backgroundColor: AppColors.adaptiveBgPrimary(context),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildNearbyBanner(context),
              const SizedBox(height: 12),
              Expanded(
                child: _buildTripsSection(context),
              ),
            ],
          ),
        ),
        floatingActionButton: BlocBuilder<SavedTripsCubit, SavedTripsState>(
          builder: (context, state) {
            return FloatingActionButton.extended(
              onPressed: () => context.go('/plan'),
              backgroundColor: AppColors.accentAmber,
              elevation: 8,
              label: Text(
                AppStrings.of(context).savedNewTrip,
                style: AppTextStyles.button.copyWith(color: AppColors.adaptiveBgPrimary(context)),
              ),
              icon: Icon(Icons.add_rounded, color: AppColors.adaptiveBgPrimary(context)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.of(context).greeting, style: AppTextStyles.bodyMedium),
              Text(
                AppStrings.of(context).savedTitle,
                style: AppTextStyles.displaySmall,
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.adaptiveGlass(context),
                border: Border.all(color: AppColors.adaptiveBorder(context)),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: AppColors.adaptiveTextPrimary(context),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildNearbyBanner(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentAmber.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.near_me_rounded, color: AppColors.accentAmber, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.discoverNearbyTitle,
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.discoverNearbySubtitle,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLocating ? null : _exploreNearbyCity,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentAmber,
                foregroundColor: AppColors.adaptiveBgPrimary(context),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: _isLocating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }

  Future<void> _exploreNearbyCity() async {
    final strings = AppStrings.of(context);
    setState(() => _isLocating = true);
    try {
      final locationData = await sl<LocationService>().getCurrentLocation();
      if (locationData == null || !mounted) {
        if (mounted) {
          setState(() => _isLocating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.locationPermissionDenied),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      setState(() => _isLocating = false);

      // Navigate to plan screen with pre-filled destination
      // The AI will generate a REAL plan based on the real city name
      context.push('/plan', extra: {
        'prefillDestination': locationData.fullLocationDisplay,
        'lat': locationData.latitude,
        'lng': locationData.longitude,
        'countryCode': locationData.countryCode,
      });
    } catch (e) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Widget _buildTripsSection(BuildContext context) {
    return BlocBuilder<SavedTripsCubit, SavedTripsState>(
      builder: (context, state) {
        if (state is SavedTripsLoading) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: List.generate(3, (_) => const ShimmerTripCard()),
          );
        }
        if (state is SavedTripsLoaded) {
          if (state.trips.isEmpty) {
            return _buildEmpty(context);
          }
          return _buildTripList(context, state.trips);
        }
        if (state is SavedTripsError) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () => context.read<SavedTripsCubit>().loadTrips(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 72))
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            Text(
              AppStrings.of(context).savedEmpty,
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              AppStrings.of(context).savedEmptySubtitle,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            GradientButton(
              label: AppStrings.of(context).startFirstTrip,
              icon: Icons.auto_awesome_rounded,
              onPressed: () => context.go('/plan'),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildTripList(BuildContext context, List<TripEntity> trips) {
    return RefreshIndicator(
      color: AppColors.accentAmber,
      backgroundColor: AppColors.adaptiveBgCard(context),
      onRefresh: () async {
        context.read<SavedTripsCubit>().loadTrips();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: trips.length,
        itemBuilder: (ctx, i) {
          final trip = trips[i];
          return _TripCard(
            trip: trip,
            index: i,
            onTap: () => context.push('/trip/${trip.id}', extra: trip),
            onDelete: () => context.read<SavedTripsCubit>().deleteTrip(trip.id),
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripEntity trip;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.adaptiveBgCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.adaptiveBorder(context)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  Hero(
                    tag: 'trip_hero_${trip.id}',
                    child: CachedHeroImage(
                      url: trip.displayImageUrl,
                      height: 160,
                      placeholder: () => _buildHeroPlaceholder(),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.adaptiveBgCard(context).withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: StatusBadge(status: trip.status),
                  ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.displayDestination(context),
                          style: AppTextStyles.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.durationDays} ${AppStrings.of(context).planDurationDays}',
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.attach_money_rounded,
                                size: 12, color: AppColors.accentAmber),
                            Text(
                              '~\$${trip.budgetTotal.toStringAsFixed(0)}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.accentAmber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Delete
                  IconButton(
                    tooltip: AppStrings.of(context).delete,
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildHeroPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2E42), Color(0xFF0D1B2A)],
        ),
      ),
      child: const Center(
        child: Text('✈️', style: TextStyle(fontSize: 48)),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adaptiveBgCard(context),
        title: Text(AppStrings.of(context).deleteTripTitle, style: AppTextStyles.headlineSmall),
        content: Text(
          AppStrings.of(context).deleteTripConfirm(trip.displayDestination(context)),
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Haptics.warning();
              Navigator.pop(ctx);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.of(context).delete),
          ),
        ],
      ),
    );
  }
}
