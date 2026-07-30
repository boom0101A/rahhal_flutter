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
import '../../../../shared/widgets/cached_hero_image.dart';
import '../../../restaurants/presentation/widgets/restaurant_detail_sheet.dart';
import '../../../restaurants/presentation/widgets/restaurant_map_button.dart';
import '../../../hotels/presentation/widgets/hotel_detail_sheet.dart';

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
          tooltip: strings.back,
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
            final hotels = items.where((i) => i.favorite.itemType == 'hotel').toList();

            return RefreshIndicator(
              color: AppColors.accentAmber,
              backgroundColor: AppColors.adaptiveBgCard(context),
              onRefresh: () => context.read<FavoritesCubit>().loadFavorites(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ..._buildSection(
                    context,
                    strings.favoritesStops,
                    stops,
                    _buildFavoriteStopCard,
                  ),
                  if (stops.isNotEmpty && (restaurants.isNotEmpty || hotels.isNotEmpty))
                    const SizedBox(height: 16),
                  ..._buildSection(
                    context,
                    strings.favoritesRestaurants,
                    restaurants,
                    _buildFavoriteRestaurantCard,
                  ),
                  if (restaurants.isNotEmpty && hotels.isNotEmpty) const SizedBox(height: 16),
                  ..._buildSection(
                    context,
                    strings.favoritesHotels,
                    hotels,
                    _buildFavoriteHotelCard,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Splits [items] into a headline followed by one card per item — grouped
  /// under a destination subheader when the section spans more than one
  /// trip destination, otherwise shown as a flat list.
  List<Widget> _buildSection(
    BuildContext context,
    String title,
    List<FavoriteItem> items,
    Widget Function(BuildContext, FavoriteItem) cardBuilder,
  ) {
    if (items.isEmpty) return [];
    final strings = AppStrings.of(context);

    final grouped = <String, List<FavoriteItem>>{};
    for (final item in items) {
      final dest = item.tripDestination;
      final key = (dest != null && dest.isNotEmpty) ? dest : strings.favoritesOtherDestination;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(title, style: AppTextStyles.headlineSmall),
      ),
    ];

    if (grouped.length <= 1) {
      widgets.addAll(items.map((item) => cardBuilder(context, item)));
    } else {
      for (final entry in grouped.entries) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              entry.key,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentTurquoise),
            ),
          ),
        );
        widgets.addAll(entry.value.map((item) => cardBuilder(context, item)));
      }
    }

    return widgets;
  }

  Future<void> _showNoteDialog(BuildContext context, FavoriteItem item) async {
    final strings = AppStrings.of(context);
    final cubit = context.read<FavoritesCubit>();
    final controller = TextEditingController(text: item.favorite.notes ?? '');

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.favoriteEditNote),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(hintText: strings.favoriteNoteHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.save),
          ),
        ],
      ),
    );

    if (save == true) {
      final trimmed = controller.text.trim();
      cubit.updateNotes(
        item.favorite.itemType,
        item.favorite.itemRefId,
        trimmed.isEmpty ? null : trimmed,
      );
    }
  }

  void _removeWithUndo(BuildContext context, FavoriteItem item) {
    final strings = AppStrings.of(context);
    final cubit = context.read<FavoritesCubit>();
    final itemType = item.favorite.itemType;
    final itemRefId = item.favorite.itemRefId;
    final destinationName = item.favorite.destinationName;
    final notes = item.favorite.notes;

    Haptics.toggle();
    cubit.toggleFavorite(itemType, itemRefId, destinationName: destinationName, notes: notes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.favoriteRemoved),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: strings.undo,
          onPressed: () => cubit.toggleFavorite(
            itemType,
            itemRefId,
            destinationName: destinationName,
            notes: notes,
          ),
        ),
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
                        color: isDark ? AppColors.adaptiveTextPrimary(context) : const Color(0xFF0D1B2A),
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
                          color: isDark ? AppColors.adaptiveTextSecondary(context) : const Color(0xFF4B5563),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.favorite.notes != null && item.favorite.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.favorite.notes!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: AppColors.accentTurquoise,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sticky_note_2_outlined, size: 20),
                tooltip: strings.favoriteEditNote,
                onPressed: () => _showNoteDialog(context, item),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: AppColors.error),
                tooltip: strings.removeFromFavorites,
                onPressed: () => _removeWithUndo(context, item),
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
      child: GestureDetector(
        onTap: () => RestaurantDetailSheet.show(context, rest),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      // Real Google Places photo (falls back to a 🍴 tile when
                      // the restaurant has no image), matching the Restaurants
                      // tab instead of the old fixed emoji.
                      child: CachedHeroImage(
                        url: rest.displayImageUrl,
                        height: 44,
                        fit: BoxFit.cover,
                        placeholderEmoji: '🍴',
                      ),
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
                            color: isDark
                                ? AppColors.adaptiveTextPrimary(context)
                                : const Color(0xFF0D1B2A),
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
                              color: isDark
                                  ? AppColors.adaptiveTextSecondary(context)
                                  : const Color(0xFF4B5563),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (item.favorite.notes != null && item.favorite.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.favorite.notes!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: AppColors.accentTurquoise,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sticky_note_2_outlined, size: 20),
                    tooltip: strings.favoriteEditNote,
                    onPressed: () => _showNoteDialog(context, item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: AppColors.error),
                    tooltip: strings.removeFromFavorites,
                    onPressed: () => _removeWithUndo(context, item),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RestaurantMapButton(restaurant: rest),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildFavoriteHotelCard(BuildContext context, FavoriteItem item) {
    final hotel = item.hotel!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => HotelDetailSheet.show(context, hotel),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CachedHeroImage(
                    url: hotel.displayImageUrl,
                    height: 44,
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
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isDark ? AppColors.adaptiveTextPrimary(context) : const Color(0xFF0D1B2A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hotel.address != null && hotel.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hotel.address!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          color: isDark ? AppColors.adaptiveTextSecondary(context) : const Color(0xFF4B5563),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.favorite.notes != null && item.favorite.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.favorite.notes!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: AppColors.accentTurquoise,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sticky_note_2_outlined, size: 20),
                tooltip: strings.favoriteEditNote,
                onPressed: () => _showNoteDialog(context, item),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: AppColors.error),
                tooltip: strings.removeFromFavorites,
                onPressed: () => _removeWithUndo(context, item),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}
