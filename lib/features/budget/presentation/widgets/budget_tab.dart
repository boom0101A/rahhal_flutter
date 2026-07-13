import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../../../../shared/widgets/gradient_button.dart';
import '../../../../../shared/widgets/app_error_widget.dart';
import '../../../itinerary/domain/entities/day_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../cubit/budget_cubit.dart';

class BudgetTab extends StatefulWidget {
  final String tripId;

  const BudgetTab({super.key, required this.tripId});

  @override
  State<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<BudgetTab> {
  int _activeSubTab = 0; // 0: Comparison, 1: Actual Expenses
  String? _selectedDayId; // null means 'All Days'

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
          return AppErrorWidget(
            message: state.message,
            onRetry: () => context.read<BudgetCubit>().loadBudget(widget.tripId),
          );
        }
        if (state is BudgetLoaded) {
          return Column(
            children: [
              _buildSubTabSelector(context),
              Expanded(
                child: _activeSubTab == 0
                    ? _buildComparisonView(context, state)
                    : _buildActualExpensesView(context, state),
              ),
            ],
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accentAmber),
        );
      },
    );
  }

  Widget _buildSubTabSelector(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.adaptiveGlass(context),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.adaptiveBorder(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSubTabButton(
              context,
              index: 0,
              label: strings.expenseComparison,
            ),
          ),
          Expanded(
            child: _buildSubTabButton(
              context,
              index: 1,
              label: strings.expenseActual,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(BuildContext context, {required int index, required String label}) {
    final isSelected = _activeSubTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        _activeSubTab = index;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentAmber : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? AppColors.bgPrimary : AppColors.adaptiveTextSecondary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Overview & Comparison ──────────────────────────────────────────────────

  Widget _buildComparisonView(BuildContext context, BudgetLoaded state) {
    final strings = AppStrings.of(context);
    
    // Aggregate estimated total
    final estimatedTotal = state.breakdown.total;
    
    // Aggregate actual spent total
    final actualTotal = state.expenses.fold<double>(0, (sum, item) => sum + item.amount);

    final ratio = estimatedTotal > 0 ? (actualTotal / estimatedTotal) : 0.0;
    final isOverBudget = actualTotal > estimatedTotal;

    // Aggregate category details
    final categoryDetails = _getCategoryComparisonData(context, state);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Comparison Total Card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.budgetDistribution,
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.expenseEstimatedTotal, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        '\$${estimatedTotal.toStringAsFixed(0)}',
                        style: AppTextStyles.headlineLarge,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(strings.expenseActualTotal, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        '\$${actualTotal.toStringAsFixed(0)}',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: isOverBudget ? AppColors.error : AppColors.accentTurquoise,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Comparison bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: ratio > 1.0 ? 1.0 : ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOverBudget
                              ? [AppColors.error, const Color(0xFFEF9A9A)]
                              : [AppColors.accentTurquoise, const Color(0xFF80CBC4)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Spent stats text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(ratio * 100).toStringAsFixed(0)}% ${strings.expenseStatusSpentOf}',
                    style: AppTextStyles.bodySmall,
                  ),
                  if (isOverBudget)
                    Text(
                      '${strings.expenseStatusOver} \$${(actualTotal - estimatedTotal).toStringAsFixed(0)} ⚠️',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 24),

        // Comparison Breakdown List
        Text(strings.expenseComparison, style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),

        if (categoryDetails.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(strings.budgetEmpty, style: AppTextStyles.bodyMedium),
            ),
          )
        else
          ...categoryDetails.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return _buildCategoryComparisonRow(context, item, idx);
          }),
      ],
    );
  }

  Widget _buildCategoryComparisonRow(
      BuildContext context, _CategoryCompData item, int index) {
    final ratio = item.estimated > 0 ? (item.actual / item.estimated) : 0.0;
    final isOver = item.actual > item.estimated;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Emoji Card icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
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
                      Text(item.name, style: AppTextStyles.titleSmall),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\$${item.actual.toStringAsFixed(0)} ',
                              style: AppTextStyles.dataSmall.copyWith(
                                color: isOver ? AppColors.error : AppColors.adaptiveTextPrimary(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '/ \$${item.estimated.toStringAsFixed(0)}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.adaptiveTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Sub progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio > 1.0 ? 1.0 : ratio,
                      backgroundColor: item.color.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOver ? AppColors.error : item.color,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 400.ms)
        .slideX(begin: 0.05, end: 0);
  }

  List<_CategoryCompData> _getCategoryComparisonData(
      BuildContext context, BudgetLoaded state) {
    final strings = AppStrings.of(context);
    final breakdown = state.breakdown;

    // Category lists
    final categories = ['accommodation', 'food', 'transport', 'activities', 'shopping', 'other'];
    final emojis = {
      'accommodation': '🏨',
      'food': '🍽️',
      'transport': '🚕',
      'activities': '🎭',
      'shopping': '🛍️',
      'other': '💰',
    };
    final colors = {
      'accommodation': AppColors.chart1,
      'food': AppColors.chart2,
      'transport': AppColors.chart3,
      'activities': AppColors.chart4,
      'shopping': AppColors.chart5,
      'other': AppColors.textSecondary,
    };

    // Calculate actual mapping
    final actuals = <String, double>{};
    for (final exp in state.expenses) {
      actuals[exp.category] = (actuals[exp.category] ?? 0.0) + exp.amount;
    }

    final estimates = <String, double>{
      'accommodation': breakdown.accommodation,
      'food': breakdown.food,
      'transport': breakdown.transport,
      'activities': breakdown.activities,
      'shopping': breakdown.shopping,
      'other': breakdown.other,
    };

    return categories
        .map((cat) {
          final est = estimates[cat] ?? 0.0;
          final act = actuals[cat] ?? 0.0;
          return _CategoryCompData(
            key: cat,
            name: strings.budgetItemCategory(cat),
            emoji: emojis[cat] ?? '💰',
            color: colors[cat] ?? AppColors.accentAmber,
            estimated: est,
            actual: act,
          );
        })
        .where((c) => c.estimated > 0 || c.actual > 0)
        .toList();
  }

  // ─── Actual Expenses View ──────────────────────────────────────────────────

  Widget _buildActualExpensesView(BuildContext context, BudgetLoaded state) {
    final strings = AppStrings.of(context);
    
    // Filter expenses by selected day
    final filteredExpenses = state.expenses.where((exp) {
      if (_selectedDayId == null) return true;
      return exp.dayId == _selectedDayId;
    }).toList();

    return Column(
      children: [
        // Day selectors row
        _buildDaySelectorRow(context, state.days),

        // Add Expense Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GradientButton(
            label: strings.expenseAdd,
            icon: Icons.add_rounded,
            onPressed: () => _showAddExpenseBottomSheet(context, state),
          ),
        ),

        // Expense List
        Expanded(
          child: filteredExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💸', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(strings.expenseNoExpenses, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (ctx, idx) {
                    final exp = filteredExpenses[idx];
                    return _buildExpenseListItem(context, exp, state.days);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDaySelectorRow(BuildContext context, List<DayEntity> days) {
    final strings = AppStrings.of(context);
    
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All days chip
          _buildDayChip(
            label: strings.expenseAllDays,
            isSelected: _selectedDayId == null,
            onTap: () => setState(() => _selectedDayId = null),
          ),
          const SizedBox(width: 8),
          // Day specific chips
          ...days.map((day) {
            final label = '${strings.dayPrefix} ${day.dayNumber}';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildDayChip(
                label: label,
                isSelected: _selectedDayId == day.id,
                onTap: () => setState(() => _selectedDayId = day.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentAmber : AppColors.adaptiveGlass(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.accentAmber : AppColors.adaptiveBorder(context),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? AppColors.bgPrimary : AppColors.adaptiveTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseListItem(
      BuildContext context, ExpenseEntity exp, List<DayEntity> days) {
    final strings = AppStrings.of(context);

    // Get day label
    String dayLabel = strings.expenseGeneral;
    if (exp.dayId != null) {
      final day = days.where((d) => d.id == exp.dayId).firstOrNull;
      if (day != null) {
        dayLabel = '${strings.dayPrefix} ${day.dayNumber}';
      }
    }

    final emoji = switch (exp.category) {
      'accommodation' => '🏨',
      'food' => '🍽️',
      'transport' => '🚕',
      'activities' => '🎭',
      'shopping' => '🛍️',
      _ => '💰',
    };

    final color = switch (exp.category) {
      'accommodation' => AppColors.chart1,
      'food' => AppColors.chart2,
      'transport' => AppColors.chart3,
      'activities' => AppColors.chart4,
      'shopping' => AppColors.chart5,
      _ => AppColors.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Category Emoji icon
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
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exp.description != null && exp.description!.isNotEmpty
                        ? exp.description!
                        : strings.budgetItemCategory(exp.category),
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        strings.budgetItemCategory(exp.category),
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dayLabel,
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Price + Delete
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-\$${exp.amount.toStringAsFixed(0)}',
                  style: AppTextStyles.dataMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDeleteExpense(context, exp),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.textSecondary, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteExpense(BuildContext context, ExpenseEntity exp) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgPopover,
        title: Text(strings.delete, style: AppTextStyles.headlineMedium),
        content: Text(strings.expenseDeleteConfirm, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<BudgetCubit>().deleteExpense(widget.tripId, exp.id);
              Navigator.pop(ctx);
            },
            child: Text(strings.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseBottomSheet(BuildContext context, BudgetLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<BudgetCubit>()),
        ],
        child: _AddExpenseBottomSheet(
          tripId: widget.tripId,
          days: state.days,
          initialDayId: _selectedDayId,
        ),
      ),
    );
  }
}

class _CategoryCompData {
  final String key;
  final String name;
  final String emoji;
  final Color color;
  final double estimated;
  final double actual;

  _CategoryCompData({
    required this.key,
    required this.name,
    required this.emoji,
    required this.color,
    required this.estimated,
    required this.actual,
  });
}

// ─── Add Expense Bottom Sheet Form ───────────────────────────────────────────

class _AddExpenseBottomSheet extends StatefulWidget {
  final String tripId;
  final List<DayEntity> days;
  final String? initialDayId;

  const _AddExpenseBottomSheet({
    required this.tripId,
    required this.days,
    this.initialDayId,
  });

  @override
  State<_AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<_AddExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  String _selectedCategory = 'food';
  String? _selectedDayId;

  @override
  void initState() {
    super.initState();
    _selectedDayId = widget.initialDayId;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isArabic = strings.languageCode == 'ar';

    final categories = ['accommodation', 'food', 'transport', 'activities', 'shopping', 'other'];
    final categoryEmojis = {
      'accommodation': '🏨',
      'food': '🍽️',
      'transport': '🚕',
      'activities': '🎭',
      'shopping': '🛍️',
      'other': '💰',
    };

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgPopover,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.expenseAdd,
                    style: AppTextStyles.displaySmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount field
              Text(strings.expenseCategoryTitle, style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.accentAmber),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: isArabic ? null : '\$ ',
                  suffixText: isArabic ? ' دولار' : null,
                  hintText: strings.expenseAmountHint,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return strings.errorGeneral; // generic error
                  }
                  final amount = double.tryParse(val.trim());
                  if (amount == null || amount <= 0) {
                    return strings.errorGeneral;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Selector
              Text(strings.expenseCategory, style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final emoji = categoryEmojis[cat] ?? '💰';
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji),
                        const SizedBox(width: 6),
                        Text(strings.budgetItemCategory(cat)),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                    selectedColor: AppColors.accentAmber,
                    backgroundColor: AppColors.glass,
                    checkmarkColor: AppColors.bgPrimary,
                    labelStyle: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? AppColors.bgPrimary : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Day Dropdown
              Text(strings.expenseDay, style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                dropdownColor: AppColors.bgPopover,
                initialValue: _selectedDayId,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(strings.expenseGeneral, style: AppTextStyles.bodyMedium),
                  ),
                  ...widget.days.map((day) {
                    return DropdownMenuItem<String?>(
                      value: day.id,
                      child: Text(
                        '${strings.dayPrefix} ${day.dayNumber}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }),
                ],
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  setState(() => _selectedDayId = val);
                },
              ),
              const SizedBox(height: 20),

              // Description Field
              Text(strings.expenseDescription, style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: strings.expenseDescriptionHint,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              GradientButton(
                label: strings.expenseAdd,
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text.trim());
    final desc = _descCtrl.text.trim();
    final expense = ExpenseEntity(
      id: const Uuid().v4(),
      tripId: widget.tripId,
      dayId: _selectedDayId,
      category: _selectedCategory,
      description: desc.isNotEmpty ? desc : null,
      amount: amount,
      spentAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    context.read<BudgetCubit>().addExpense(expense);
    Navigator.pop(context);
  }
}
