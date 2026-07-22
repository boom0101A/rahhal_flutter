import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../../../../shared/widgets/cached_hero_image.dart';
import '../../../../../shared/widgets/shimmer_loader.dart';
import '../../../../../shared/widgets/app_badges.dart';
import '../../../../../shared/widgets/dual_currency_text.dart';
import '../../../weather/presentation/widgets/weather_banner.dart';
import '../cubit/itinerary_cubit.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../domain/entities/day_entity.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../shared/widgets/app_error_widget.dart';
import '../../../../../core/services/map_launcher_service.dart';

class ItineraryTab extends StatelessWidget {
  final String tripId;
  final String? countryCode;
  final double? tripLat;
  final double? tripLon;

  const ItineraryTab({
    super.key,
    required this.tripId,
    this.countryCode,
    this.tripLat,
    this.tripLon,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItineraryCubit, ItineraryState>(
      builder: (context, state) {
        if (state is ItineraryLoading) {
          return _buildSkeleton();
        }
        if (state is ItineraryError) {
          return _buildError(context, state.message);
        }
        if (state is ItineraryLoaded) {
          return _buildContent(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, ItineraryLoaded state) {
    // Use coords from first loaded stop, or fallback to provided tripLat/tripLon
    final firstStop = state.selectedDayStops.isNotEmpty
        ? state.selectedDayStops.first
        : null;
    final lat = firstStop?.latitude ?? tripLat;
    final lon = firstStop?.longitude ?? tripLon;
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode == 'ar' ? 'ar' : 'en';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Weather Banner
        WeatherBanner(lat: lat, lon: lon, lang: lang),
        // Day selector
        _DaySelector(
          days: state.days,
          selectedIndex: state.selectedDayIndex,
          onSelect: (i) => context.read<ItineraryCubit>().selectDay(i),
        ),
        const SizedBox(height: 16),

        // Day summary
        if (state.selectedDay.theme != null) ...[
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text('🗓️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.selectedDay.theme!,
                        style: AppTextStyles.titleMedium,
                      ),
                      if (state.selectedDay.summary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          state.selectedDay.summary!,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Stops header with a reorder action (only when there's >1 stop to move)
        if (!state.isLoadingStops && state.selectedDayStops.length > 1) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.of(context).itineraryStopsTitle,
                  style: AppTextStyles.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openReorderSheet(
                  context,
                  dayId: state.selectedDay.id,
                  stops: state.selectedDayStops,
                ),
                icon: const Icon(Icons.swap_vert_rounded,
                    size: 18, color: AppColors.accentAmber),
                label: Text(
                  AppStrings.of(context).reorder,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.accentAmber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],

        // Stops with timeline
        if (state.isLoadingStops)
          ...List.generate(3, (_) => const ShimmerStopCard())
        else if (state.selectedDayStops.isEmpty)
          _buildEmptyDay(context)
        else
          ...state.selectedDayStops.asMap().entries.map(
                (e) => _StopTimelineItem(
                  stop: e.value,
                  isLast: e.key == state.selectedDayStops.length - 1,
                  index: e.key,
                  countryCode: countryCode,
                  onTap: () => context.push(
                      '/trip/${e.value.tripId}/stop/${e.value.id}',
                      extra: e.value),
                ),
              ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Day selector skeleton
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (ctx, __) => Container(
              margin: const EdgeInsetsDirectional.only(start: 8),
              width: 70,
              decoration: BoxDecoration(
                color: AppColors.adaptiveBgCard(ctx),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(4, (_) => const ShimmerStopCard()),
      ],
    );
  }

  Widget _buildError(BuildContext context, String code) {
    final strings = AppStrings.of(context);
    final message = switch (code) {
      'no-days-found' => strings.noDaysFound,
      'stop-not-found' => strings.stopNotFound,
      _ => code,
    };
    return AppErrorWidget(
      message: message,
      onRetry: () => context.read<ItineraryCubit>().loadItinerary(tripId),
    );
  }

  /// Opens a bottom sheet where the day's stops can be dragged into a new
  /// order. On confirm it persists via the cubit's reorderStops. Kept as a
  /// dedicated sheet so the main timeline (with its connector lines) stays
  /// clean rather than turning into a drag surface.
  void _openReorderSheet(
    BuildContext context, {
    required String dayId,
    required List<StopEntity> stops,
  }) {
    final cubit = context.read<ItineraryCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReorderStopsSheet(
        stops: stops,
        onSave: (orderedIds) => cubit.reorderStops(dayId, orderedIds),
      ),
    );
  }

  Widget _buildEmptyDay(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(AppStrings.of(context).noStopsForDay, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ─── Day Selector ──────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  final List<DayEntity> days;
  final int selectedIndex;
  final void Function(int) onSelect;

  const _DaySelector({
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (ctx, i) {
          final day = days[i];
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsetsDirectional.only(
                start: i == 0 ? 20 : 8,
                end: i == days.length - 1 ? 20 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentAmber : AppColors.adaptiveGlass(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accentAmber : AppColors.adaptiveBorder(context),
                ),
                boxShadow: isSelected ? AppColors.amberGlow : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${AppStrings.of(context).planDayLabelPrefix} ${day.dayNumber}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.bgPrimary
                          : AppColors.adaptiveTextSecondary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (day.date != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${day.date!.day} ${AppStrings.of(context).monthName(day.date!.month)}',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10,
                        color: isSelected
                            ? AppColors.bgPrimary.withValues(alpha: 0.7)
                            : AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Stop Timeline Item ────────────────────────────────────────────────────

class _StopTimelineItem extends StatelessWidget {
  final StopEntity stop;
  final bool isLast;
  final int index;
  final String? countryCode;
  final VoidCallback onTap;

  const _StopTimelineItem({
    required this.stop,
    required this.isLast,
    required this.index,
    required this.onTap,
    this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline thread
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Time label
                Text(
                  stop.startTime ?? '',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accentAmber,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentAmber,
                    boxShadow: AppColors.amberGlow,
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.accentAmber.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: CachedHeroImage(
                        url: stop.displayImageUrl,
                        height: 130,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(stop.categoryEmoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stop.displayName(context),
                                  style: AppTextStyles.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              BlocBuilder<FavoritesCubit, FavoritesState>(
                                builder: (context, state) {
                                  final isFav = context.read<FavoritesCubit>().isKeyFavorite('stop', stop.id);
                                  return IconButton(
                                    icon: Icon(
                                      isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                      color: isFav ? AppColors.error : AppColors.adaptiveTextSecondary(context),
                                      size: 20,
                                    ),
                                    tooltip: isFav
                                        ? AppStrings.of(context).removeFromFavorites
                                        : AppStrings.of(context).addToFavorites,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Haptics.toggle();
                                      context.read<FavoritesCubit>().toggleFavorite(
                                        'stop',
                                        stop.id,
                                        destinationName: stop.displayName(context),
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
                              Icon(
                                Icons.chevron_left_rounded,
                                color: AppColors.adaptiveTextSecondary(context),
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              PeriodBadge(period: stop.timeOfDay),
                              const SizedBox(width: 8),
                              CategoryChip(category: stop.category, small: true),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _infoChip(context, Icons.schedule_rounded, AppStrings.of(context).formatDuration(stop.durationMinutes)),
                              const SizedBox(width: 8),
                              if (stop.costUsd == 0)
                                _infoChip(context, Icons.attach_money_rounded, AppStrings.of(context).free)
                              else
                                _costChip(context, stop.costUsd),
                              if (stop.bookingRequired) ...[
                                const SizedBox(width: 8),
                                _infoChip(context, Icons.event_available_rounded, AppStrings.of(context).infoChipBook),
                              ],
                            ],
                          ),
                          if (stop.aiTip != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accentAmber.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.accentAmber.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('✨', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      stop.aiTip!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.accentAmber
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          // Quick Actions Row: Google Maps & Uber
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => MapLauncherService.openInGoogleMaps(
                                    placeName: stop.displayName(context),
                                    lat: stop.latitude,
                                    lon: stop.longitude,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentAmber.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.near_me_rounded, size: 14, color: AppColors.accentAmber),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppStrings.of(context).openInMaps,
                                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentAmber, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => MapLauncherService.openUberRide(
                                    placeName: stop.displayName(context),
                                    lat: stop.latitude,
                                    lon: stop.longitude,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.adaptiveGlass(context),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.adaptiveBorder(context)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.local_taxi_rounded, size: 14, color: AppColors.accentTurquoise),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppStrings.of(context).orderUber,
                                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.adaptiveTextPrimary(context), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 50 * index),
                  ),
            ),
          ),
        ],
      ).animate().slideX(
            begin: 0.05,
            end: 0,
            delay: Duration(milliseconds: 30 * index),
            duration: 400.ms,
          ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.adaptiveTextSecondary(context)),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }

  Widget _costChip(BuildContext context, double costUsd) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.attach_money_rounded, size: 12,
            color: AppColors.adaptiveTextSecondary(context)),
        const SizedBox(width: 3),
        DualCurrencyText(
          amountUsd: costUsd,
          countryCode: countryCode,
          compact: true,
          primaryStyle: AppTextStyles.labelSmall,
        ),
      ],
    );
  }
}

/// Bottom sheet listing a day's stops in a ReorderableListView. Editing a
/// local copy and only persisting on "save" keeps a mid-drag state from
/// hitting the database on every frame.
class _ReorderStopsSheet extends StatefulWidget {
  final List<StopEntity> stops;
  final void Function(List<String> orderedStopIds) onSave;

  const _ReorderStopsSheet({required this.stops, required this.onSave});

  @override
  State<_ReorderStopsSheet> createState() => _ReorderStopsSheetState();
}

class _ReorderStopsSheetState extends State<_ReorderStopsSheet> {
  late List<StopEntity> _stops;

  @override
  void initState() {
    super.initState();
    _stops = List.of(widget.stops);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.adaptiveBgPrimary(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.adaptiveBorder(context),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.swap_vert_rounded,
                        color: AppColors.accentAmber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(strings.reorderStopsTitle,
                          style: AppTextStyles.headlineSmall),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(strings.reorderStopsHint,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.adaptiveTextSecondary(context))),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: _stops.length,
                  // onReorderItem already accounts for the removed item, so no
                  // manual newIndex adjustment is needed (unlike onReorder).
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final item = _stops.removeAt(oldIndex);
                      _stops.insert(newIndex, item);
                    });
                    Haptics.toggle();
                  },
                  itemBuilder: (context, index) {
                    final stop = _stops[index];
                    return Container(
                      key: ValueKey(stop.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.adaptiveGlass(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.adaptiveBorder(context)),
                      ),
                      child: Row(
                        children: [
                          Text('${index + 1}',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.accentAmber)),
                          const SizedBox(width: 10),
                          Text(stop.categoryEmoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              stop.displayName(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSmall,
                            ),
                          ),
                          Icon(Icons.drag_handle_rounded,
                              color: AppColors.adaptiveTextSecondary(context)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, 12 + MediaQuery.of(context).padding.bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(strings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onSave(_stops.map((s) => s.id).toList());
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentAmber,
                          foregroundColor: AppColors.bgPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(strings.save),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
