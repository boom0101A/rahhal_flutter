import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'entities/budget_item_entity.dart';

/// Single source of truth for the 6 budget category keys and their
/// emoji/color/planned-amount lookups — previously duplicated independently
/// across budget_tab.dart and planned_vs_actual_chart.dart.
const List<String> kBudgetCategoryKeys = [
  'accommodation',
  'food',
  'transport',
  'activities',
  'shopping',
  'other',
];

const Map<String, String> kBudgetCategoryEmoji = {
  'accommodation': '🏨',
  'food': '🍽️',
  'transport': '🚕',
  'activities': '🎭',
  'shopping': '🛍️',
  'other': '💰',
};

Color budgetCategoryColor(BuildContext context, String key) => switch (key) {
      'accommodation' => AppColors.chart1,
      'food' => AppColors.chart2,
      'transport' => AppColors.chart3,
      'activities' => AppColors.chart4,
      'shopping' => AppColors.chart5,
      _ => AppColors.adaptiveTextSecondary(context),
    };

double budgetPlannedFor(BudgetBreakdown breakdown, String key) => switch (key) {
      'accommodation' => breakdown.accommodation,
      'food' => breakdown.food,
      'transport' => breakdown.transport,
      'activities' => breakdown.activities,
      'shopping' => breakdown.shopping,
      _ => breakdown.other,
    };
