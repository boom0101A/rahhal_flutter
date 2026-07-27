import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/budget_item_entity.dart';
import '../../domain/entities/expense_entity.dart';

/// Side-by-side bars per category: what the trip budgeted vs what was actually
/// spent — so overspending is visible at a glance instead of buried in totals.
class PlannedVsActualChart extends StatelessWidget {
  final BudgetBreakdown planned;
  final List<ExpenseEntity> expenses;

  const PlannedVsActualChart({
    super.key,
    required this.planned,
    required this.expenses,
  });

  /// Category keys shared by the planned breakdown and logged expenses.
  static const _categories = [
    'accommodation',
    'food',
    'transport',
    'activities',
    'shopping',
  ];

  double _plannedFor(String category) => switch (category) {
        'accommodation' => planned.accommodation,
        'food' => planned.food,
        'transport' => planned.transport,
        'activities' => planned.activities,
        'shopping' => planned.shopping,
        _ => planned.other,
      };

  double _actualFor(String category) => expenses
      .where((e) => e.category.toLowerCase() == category)
      .fold(0.0, (sum, e) => sum + e.amount);

  String _label(String category, AppStrings s) => switch (category) {
        'accommodation' => s.budgetAccommodation,
        'food' => s.budgetFood,
        'transport' => s.budgetTransport,
        'activities' => s.budgetActivities,
        'shopping' => s.budgetShopping,
        _ => s.budgetOther,
      };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    // Only chart the categories that carry a number on either side — empty
    // columns are noise on a phone-width chart.
    final rows = _categories
        .map((c) => (
              key: c,
              planned: _plannedFor(c),
              actual: _actualFor(c),
            ))
        .where((r) => r.planned > 0 || r.actual > 0)
        .toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    final totalActual = rows.fold(0.0, (s, r) => s + r.actual);
    final maxValue = rows
        .map((r) => r.planned > r.actual ? r.planned : r.actual)
        .reduce((a, b) => a > b ? a : b);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.budgetChartTitle, style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          _legend(context, strings),
          const SizedBox(height: 16),

          if (totalActual == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  strings.budgetNoExpensesYet,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.adaptiveTextSecondary(context)),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  // Headroom so the tallest bar isn't flush with the top.
                  maxY: maxValue * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        '\$${rod.toY.round()}',
                        AppTextStyles.labelSmall.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= rows.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _label(rows[i].key, strings),
                              style: AppTextStyles.labelSmall.copyWith(
                                color:
                                    AppColors.adaptiveTextSecondary(context),
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.adaptiveBorder(context)
                          .withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < rows.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: rows[i].planned,
                            color: AppColors.accentTurquoise,
                            width: 9,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          BarChartRodData(
                            toY: rows[i].actual,
                            // Red the moment actual passes planned — that's the
                            // single thing the user needs to notice here.
                            color: rows[i].actual > rows[i].planned
                                ? AppColors.error
                                : AppColors.accentAmber,
                            width: 9,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, AppStrings strings) {
    return Row(
      children: [
        _legendDot(AppColors.accentTurquoise, strings.budgetPlanned, context),
        const SizedBox(width: 14),
        _legendDot(AppColors.accentAmber, strings.budgetActual, context),
      ],
    );
  }

  Widget _legendDot(Color color, String label, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.adaptiveTextSecondary(context))),
      ],
    );
  }
}
