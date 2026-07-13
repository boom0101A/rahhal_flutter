# ملف كود Dart: lib\features\budget\presentation\widgets\budget_tab.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../cubit/budget_cubit.dart';

class BudgetTab extends StatelessWidget {
  final String tripId;

  const BudgetTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, state) {
        if (state is BudgetLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentAmber),
          );
        }
        if (state is BudgetError) {
          return Center(
            child: Text(state.message, style: AppTextStyles.bodyMedium),
          );
        }
        if (state is BudgetLoaded) {
          return _buildContent(state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BudgetLoaded state) {
    final breakdown = state.breakdown;
    final categories = [
      ('accommodation', AppStrings.budgetItemCategory('accommodation'), AppColors.chart1, breakdown.accommodation),
      ('food', AppStrings.budgetItemCategory('food'), AppColors.chart2, breakdown.food),
      ('transport', AppStrings.budgetItemCategory('transport'), AppColors.chart3, breakdown.transport),
      ('activities', AppStrings.budgetItemCategory('activities'), AppColors.chart4, breakdown.activities),
      ('shopping', AppStrings.budgetItemCategory('shopping'), AppColors.chart5, breakdown.shopping),
    ].where((c) => c.$4 > 0).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Total card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(AppStrings.budgetTotal, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              Text(
                '~\$${breakdown.total.toStringAsFixed(0)}',
                style: AppTextStyles.amberBold.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.budgetEstimatedUsd,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 20),

        // Donut chart
        if (categories.isNotEmpty) ...[
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(AppStrings.budgetDistribution, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 60,
                      sections: categories.asMap().entries.map((e) {
                        final (_, label, color, amount) = e.value;
                        final pct = breakdown.percentOf(amount);
                        return PieChartSectionData(
                          color: color,
                          value: amount,
                          radius: 30,
                          title: '${pct.toStringAsFixed(0)}%',
                          titleStyle: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: categories.map((c) {
                    final (_, label, color, a) = c;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(label, style: AppTextStyles.labelSmall),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          // Category breakdown list
          Text(AppStrings.budgetDetails, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          ...categories.asMap().entries.map(
                (e) => _BudgetRow(
                  category: e.value.$1,
                  label: e.value.$2,
                  color: e.value.$3,
                  amount: e.value.$4,
                  percent: breakdown.percentOf(e.value.$4),
                  index: e.key,
                ),
              ),
        ],
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String category;
  final String label;
  final Color color;
  final double amount;
  final double percent;
  final int index;

  const _BudgetRow({
    required this.category,
    required this.label,
    required this.color,
    required this.amount,
    required this.percent,
    required this.index,
  });

  String get emoji => switch (category) {
        'accommodation' => '🏨',
        'food' => '🍽️',
        'transport' => '🚕',
        'activities' => '🎭',
        'shopping' => '🛍️',
        _ => '💰',
      };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Color dot + emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: AppTextStyles.titleSmall),
                    Text(
                      '\$${amount.toStringAsFixed(0)}',
                      style: AppTextStyles.dataSmall.copyWith(
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 400.ms)
        .slideX(begin: 0.05, end: 0);
  }
}

```
