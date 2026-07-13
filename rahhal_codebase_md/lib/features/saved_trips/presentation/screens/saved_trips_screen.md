# ملف كود Dart: lib\features\saved_trips\presentation\screens\saved_trips_screen.dart

```dart
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
import '../../../../shared/widgets/glass_card.dart';
import '../cubit/saved_trips_cubit.dart';
import '../../../trip_planner/domain/entities/trip_entity.dart';

class SavedTripsScreen extends StatelessWidget {
  const SavedTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SavedTripsCubit>()..loadTrips(),
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.greeting, style: AppTextStyles.bodyMedium),
                        Text(AppStrings.savedTitle, style: AppTextStyles.displaySmall),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.glass,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: BlocBuilder<SavedTripsCubit, SavedTripsState>(
                  builder: (context, state) {
                    if (state is SavedTripsLoading) {
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children:
                            List.generate(3, (_) => const ShimmerTripCard()),
                      );
                    }
                    if (state is SavedTripsLoaded) {
                      if (state.trips.isEmpty) {
                        return _buildEmpty(context);
                      }
                      return _buildTripList(context, state.trips);
                    }
                    if (state is SavedTripsError) {
                      return Center(
                        child: Text(state.message,
                            style: AppTextStyles.bodyMedium),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/plan'),
          backgroundColor: AppColors.accentAmber,
          elevation: 8,
          label: Text(
            AppStrings.savedNewTrip,
            style: AppTextStyles.button.copyWith(color: AppColors.bgPrimary),
          ),
          icon: const Icon(Icons.add_rounded, color: AppColors.bgPrimary),
        ),
      ),
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
              AppStrings.savedEmpty,
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              AppStrings.savedEmptySubtitle,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            GradientButton(
              label: AppStrings.startFirstTrip,
              icon: Icons.auto_awesome_rounded,
              onPressed: () => context.go('/plan'),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildTripList(BuildContext context, List<TripEntity> trips) {
    return ListView.builder(
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
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
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
                  trip.heroImageUrl != null
                      ? Image.network(
                          trip.heroImageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildHeroPlaceholder(),
                        )
                      : _buildHeroPlaceholder(),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.bgCard.withValues(alpha: 0.7),
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
                          trip.destination,
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
                              '${trip.durationDays} ${AppStrings.planDurationDays}',
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
        backgroundColor: AppColors.bgCard,
        title: Text(AppStrings.deleteTripTitle, style: AppTextStyles.headlineSmall),
        content: Text(
          AppStrings.deleteTripConfirm(trip.destination),
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

```
