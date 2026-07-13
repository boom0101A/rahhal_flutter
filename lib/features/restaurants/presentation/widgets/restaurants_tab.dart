import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/filter_constants.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../../../../shared/widgets/cached_hero_image.dart';
import '../../../../../shared/widgets/shimmer_loader.dart';
import '../cubit/restaurants_cubit.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../../../../shared/widgets/app_error_widget.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';

class RestaurantsTab extends StatelessWidget {
  final String tripId;

  const RestaurantsTab({super.key, required this.tripId});

  static const _filters = [
    RestaurantFilter.all,
    RestaurantFilter.halal,
    RestaurantFilter.recommended,
    RestaurantFilter.seafood,
    RestaurantFilter.traditional,
    RestaurantFilter.modern,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantsCubit, RestaurantsState>(
      builder: (context, state) {
        if (state is RestaurantsLoading) {
          return _buildSkeleton();
        }
        if (state is RestaurantsError) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () => context.read<RestaurantsCubit>().loadRestaurants(tripId),
          );
        }
        if (state is RestaurantsLoaded) {
          return _buildContent(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  String _getFilterLabel(String id, BuildContext context) {
    final strings = AppStrings.of(context);
    return switch (id) {
      RestaurantFilter.all => strings.restaurantFilterAll,
      RestaurantFilter.halal => strings.restaurantHalal,
      RestaurantFilter.recommended => strings.restaurantRecommended,
      RestaurantFilter.seafood => strings.seafoodStyle,
      RestaurantFilter.traditional => strings.traditionalStyle,
      RestaurantFilter.modern => strings.modernStyle,
      _ => '',
    };
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
                  margin: const EdgeInsetsDirectional.only(start: 8),
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
                    _getFilterLabel(f, context),
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
          '${state.filteredRestaurants.length} ${AppStrings.of(context).statsRestaurants}',
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
                  Text(AppStrings.of(context).noRestaurantsForFilter,
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
      children: List.generate(6, (_) => const ShimmerRestaurantCard()),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: CachedHeroImage(
                url: restaurant.displayImageUrl,
                height: 72,
                fit: BoxFit.cover,
              ),
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
                        restaurant.displayName(context),
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
                          AppStrings.of(context).restaurantFilterRecommended,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.bgPrimary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    BlocBuilder<FavoritesCubit, FavoritesState>(
                      builder: (context, state) {
                        final isFav = context.read<FavoritesCubit>().isKeyFavorite('restaurant', restaurant.id);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                            color: isFav ? AppColors.error : AppColors.textSecondary,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            context.read<FavoritesCubit>().toggleFavorite(
                              'restaurant',
                              restaurant.id,
                              destinationName: restaurant.name,
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
                          AppStrings.of(context).restaurantFilterHalal,
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
                      '~\$${restaurant.pricePerPerson.toStringAsFixed(0)}/${AppStrings.of(context).perPerson}',
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
