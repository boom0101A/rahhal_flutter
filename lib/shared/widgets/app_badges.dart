import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';

/// The "AI" badge used throughout the app — matches Next.js AIBadge component.
class AIBadge extends StatelessWidget {
  const AIBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: AppColors.amberGradient,
        borderRadius: BorderRadius.circular(50),
        boxShadow: AppColors.amberGlow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✨', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            AppStrings.of(context).appName,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.bgPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
          begin: 1.0,
          end: 1.03,
          duration: 2000.ms,
          curve: Curves.easeInOut,
        );
  }
}

/// Period/time-of-day badge (morning / afternoon / evening).
class PeriodBadge extends StatelessWidget {
  final String period; // morning | afternoon | evening

  const PeriodBadge({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final (label, color, emoji) = switch (period) {
      'morning' => (strings.periodMorning, AppColors.accentAmber, '🌅'),
      'afternoon' => (strings.periodAfternoon, AppColors.accentTurquoise, '☀️'),
      'evening' => (strings.periodEvening, const Color(0xFF9B7FD4), '🌙'),
      _ => ('', AppColors.adaptiveTextSecondary(context), '⏰'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Category chip for stop categories.
class CategoryChip extends StatelessWidget {
  final String category;
  final bool small;

  const CategoryChip({super.key, required this.category, this.small = false});

  @override
  Widget build(BuildContext context) {
    final emoji = switch (category) {
      'museum' => '🏛️',
      'restaurant' => '🍽️',
      'park' => '🌿',
      'shopping' => '🛍️',
      'landmark' => '🗺️',
      'beach' => '🏖️',
      'mosque' => '🕌',
      'palace' => '🏰',
      'market' => '🏪',
      'viewpoint' => '🔭',
      _ => '📍',
    };

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: AppColors.adaptiveGlass(context),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.adaptiveBorder(context)),
      ),
      child: Text(
        '$emoji ${AppStrings.of(context).categoryName(category)}',
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: small ? 10 : 11,
        ),
      ),
    );
  }
}

/// Status badge for trip status (planned / active / completed).
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final (label, color) = switch (status) {
      'planned' => (strings.statusPlanned, AppColors.chart3),
      'active' => (strings.statusActive, AppColors.accentAmber),
      'completed' => (strings.statusCompleted, AppColors.success),
      _ => (status, AppColors.adaptiveTextSecondary(context)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
