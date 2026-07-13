# ملف كود Dart: lib\features\restaurants\presentation\widgets\restaurants_tab.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../../../../shared/widgets/shimmer_loader.dart';
import '../../../../../shared/widgets/app_badges.dart';
import '../cubit/restaurants_cubit.dart';
import '../../domain/entities/restaurant_entity.dart';

class RestaurantsTab extends StatelessWidget {
  final String tripId;

  const RestaurantsTab({super.key, required this.tripId});

  static const _filters = [
    'الكل',
    'حلال',
    'موصى به',
    'بحري',
    'تقليدي',
    'عصري',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantsCubit, RestaurantsState>(
      builder: (context, state) {
        if (state is RestaurantsLoading) {
          return _buildSkeleton();
        }
        if (state is RestaurantsError) {
          return Center(
            child: Text(state.message, style: AppTextStyles.bodyMedium),
          );
        }
        if (state is RestaurantsLoaded) {
          return _buildContent(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, RestaurantsLoaded state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _filters.map((f) {
              final isActive = state.activeFilter == f;
              return GestureDetector(
                onTap: () => context.read<RestaurantsCubit>().applyFilter(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accentAmber : AppColors.glass,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color:
                          isActive ? AppColors.accentAmber : AppColors.border,
                    ),
                  ),
                  child: Text(
                    f,
                    style: AppTextStyles.chip.copyWith(
                      color: isActive
                          ? AppColors.bgPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Results count
        Text(
          '${state.filteredRestaurants.length} مطعم',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),

        // Restaurant cards
        if (state.filteredRestaurants.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('لا توجد مطاعم بهذا الفلتر',
                      style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          )
        else
          ...state.filteredRestaurants.asMap().entries.map(
                (e) => _RestaurantCard(
                  restaurant: e.value,
                  index: e.key,
                ),
              ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(4, (_) => const ShimmerTripCard()),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final RestaurantEntity restaurant;
  final int index;

  const _RestaurantCard({required this.restaurant, required this.index});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / placeholder
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppColors.accentAmber.withValues(alpha: 0.15),
                  AppColors.accentTurquoise.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: const Center(
              child: Text('🍴', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + recommended badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (restaurant.isRecommended) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppColors.amberGradient,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          '✨ موصى به',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.bgPrimary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Cuisine + halal
                Wrap(
                  spacing: 6,
                  children: [
                    if (restaurant.cuisineType != null)
                      Text(restaurant.cuisineType!,
                          style: AppTextStyles.bodySmall),
                    if (restaurant.halalCertified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '✓ حلال',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Rating + price
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.accentAmber, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      restaurant.ratingLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accentAmber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.attach_money_rounded,
                        color: AppColors.textSecondary, size: 14),
                    Text(
                      restaurant.priceLabel,
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
                // AI description
                if (restaurant.aiDescription != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    restaurant.aiDescription!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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

```
