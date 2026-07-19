import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../cubit/favorites_cubit.dart';
import '../../domain/entities/favorite_item.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Load favorites on init
    context.read<FavoritesCubit>().loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0D1B2A),
            size: 20,
          ),
        ),
        title: Text(
          strings.tabFavorites,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: List.generate(4, (_) => const ShimmerStopCard()),
            );
          }
          if (state is FavoritesError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<FavoritesCubit>().loadFavorites(),
            );
          }
          if (state is FavoritesLoaded) {
            final items = state.items;
            if (items.isEmpty) {
              return RefreshIndicator(
                color: AppColors.accentAmber,
                backgroundColor: AppColors.adaptiveBgCard(context),
                onRefresh: () => context.read<FavoritesCubit>().loadFavorites(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('❤️', style: TextStyle(fontSize: 72))
                              .animate()
                              .scale(duration: 600.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 20),
                          Text(
                            strings.favoritesEmpty,
                            style: AppTextStyles.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.favoritesEmptySubtitle,
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final stops = items.where((i) => i.favorite.itemType == 'stop').toList();
            final restaurants = items.where((i) => i.favorite.itemType == 'restaurant').toList();

            return RefreshIndicator(
              color: AppColors.accentAmber,
              backgroundColor: AppColors.adaptiveBgCard(context),
              onRefresh: () => context.read<FavoritesCubit>().loadFavorites(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (stops.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(strings.favoritesStops, style: AppTextStyles.headlineSmall),
                    ),
                    ...stops.map((item) => _buildFavoriteStopCard(context, item)),
                  ],
                  if (restaurants.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(strings.favoritesRestaurants, style: AppTextStyles.headlineSmall),
                    ),
                    ...restaurants.map((item) => _buildFavoriteRestaurantCard(context, item)),
                  ],
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFavoriteStopCard(BuildContext context, FavoriteItem item) {
    final stop = item.stop!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          // Navigate to the stop detail screen nested in the trip router
          context.push('/trip/${stop.tripId}/stop/${stop.id}');
        },
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(stop.categoryEmoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.displayName(context),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isDark ? AppColors.textPrimary : const Color(0xFF0D1B2A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (stop.address != null && stop.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        stop.address!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          color: isDark ? AppColors.textSecondary : const Color(0xFF4B5563),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: AppColors.error),
                tooltip: strings.removeFromFavorites,
                onPressed: () {
                  Haptics.toggle();
                  context.read<FavoritesCubit>().toggleFavorite('stop', stop.id);
                },
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildFavoriteRestaurantCard(BuildContext context, FavoriteItem item) {
    final rest = item.restaurant!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentTurquoise.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🍴', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rest.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark ? AppColors.textPrimary : const Color(0xFF0D1B2A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (rest.cuisineType != null && rest.cuisineType!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      rest.cuisineType!,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: isDark ? AppColors.textSecondary : const Color(0xFF4B5563),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: AppColors.error),
              tooltip: strings.removeFromFavorites,
              onPressed: () {
                Haptics.toggle();
                context.read<FavoritesCubit>().toggleFavorite('restaurant', rest.id);
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}
