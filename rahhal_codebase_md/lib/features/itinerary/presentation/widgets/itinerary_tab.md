# ملف كود Dart: lib\features\itinerary\presentation\widgets\itinerary_tab.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../../../../shared/widgets/shimmer_loader.dart';
import '../../../../../shared/widgets/app_badges.dart';
import '../cubit/itinerary_cubit.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';
import '../../domain/entities/day_entity.dart';

class ItineraryTab extends StatelessWidget {
  final String tripId;

  const ItineraryTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItineraryCubit, ItineraryState>(
      builder: (context, state) {
        if (state is ItineraryLoading) {
          return _buildSkeleton();
        }
        if (state is ItineraryError) {
          return _buildError(state.message);
        }
        if (state is ItineraryLoaded) {
          return _buildContent(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, ItineraryLoaded state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
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

        // Stops with timeline
        if (state.isLoadingStops)
          ...List.generate(3, (_) => const ShimmerStopCard())
        else if (state.selectedDayStops.isEmpty)
          _buildEmptyDay()
        else
          ...state.selectedDayStops.asMap().entries.map(
                (e) => _StopTimelineItem(
                  stop: e.value,
                  isLast: e.key == state.selectedDayStops.length - 1,
                  index: e.key,
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
            itemBuilder: (_, __) => Container(
              margin: const EdgeInsets.only(left: 8),
              width: 70,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
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

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('لا توجد محطات لهذا اليوم', style: AppTextStyles.bodyMedium),
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
              margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentAmber : AppColors.glass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accentAmber : AppColors.border,
                ),
                boxShadow: isSelected ? AppColors.amberGlow : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.bgPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (day.shortDateLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      day.shortDateLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10,
                        color: isSelected
                            ? AppColors.bgPrimary.withValues(alpha: 0.7)
                            : AppColors.textSecondary.withValues(alpha: 0.6),
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
  final VoidCallback onTap;

  const _StopTimelineItem({
    required this.stop,
    required this.isLast,
    required this.index,
    required this.onTap,
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
                            stop.name,
                            style: AppTextStyles.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.textSecondary,
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
                        _infoChip(Icons.schedule_rounded, stop.durationLabel),
                        const SizedBox(width: 8),
                        _infoChip(Icons.attach_money_rounded, stop.costLabel),
                        if (stop.bookingRequired) ...[
                          const SizedBox(width: 8),
                          _infoChip(Icons.event_available_rounded, 'حجز'),
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

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

```
