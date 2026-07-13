# ملف كود Dart: lib\features\trip_planner\presentation\screens\trip_input_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';

class TripInputScreen extends StatefulWidget {
  const TripInputScreen({super.key});

  @override
  State<TripInputScreen> createState() => _TripInputScreenState();
}

class _TripInputScreenState extends State<TripInputScreen> {
  late final TextEditingController _destinationCtrl;
  int _days = 7;
  String _budget = 'mid';
  final Set<String> _styles = {'culture', 'food'};
  int _adults = 2;
  int _children = 0;
  DateTime? _startDate;

  List<(String, String, String, String)> get _budgets => [
    ('economy', AppStrings.planBudgetEconomy, '\$', AppStrings.planBudgetEconomySub),
    ('mid', AppStrings.planBudgetMid, '\$\$', AppStrings.planBudgetMidSub),
    ('luxury', AppStrings.planBudgetLuxury, '\$\$\$', AppStrings.planBudgetLuxurySub),
  ];

  List<(String, String, String)> get _travelStyles => [
    ('culture', AppStrings.styleCulture, '🏛️'),
    ('adventure', AppStrings.styleAdventure, '🧭'),
    ('food', AppStrings.styleFood, '🍽️'),
    ('shopping', AppStrings.styleShopping, '🛍️'),
    ('nature', AppStrings.styleNature, '🌿'),
    ('relax', AppStrings.styleRelax, '🌊'),
  ];

  @override
  void initState() {
    super.initState();
    _destinationCtrl = TextEditingController(text: AppStrings.defaultDestination);
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
            children: [
              // Ambient gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.0,
                      colors: [
                        AppColors.accentAmber.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go('/home'),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppColors.textPrimary, size: 20),
                          ),
                          Expanded(
                            child: Text(
                              AppStrings.planTitle,
                              style: AppTextStyles.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),

                    // Scrollable form
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        children: [
                          // AI greeting
                          _buildAIGreeting(),
                          const SizedBox(height: 20),

                          // Destination
                          _buildSectionCard(
                            title: AppStrings.planDestination,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _destinationCtrl,
                                  style: AppTextStyles.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: AppStrings.planDestinationHint,
                                    prefixIcon: const Icon(Icons.search_rounded,
                                        color: AppColors.textSecondary,
                                        size: 20),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: AppStrings.popularCities
                                      .map((c) => _buildCityChip(c))
                                      .toList(),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // Duration slider
                          _buildSectionCard(
                            title: AppStrings.planDuration,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentAmber
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                '$_days ${AppStrings.planDurationDays}',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.accentAmber,
                                ),
                              ),
                            ),
                            child: SliderTheme(
                              data: SliderTheme.of(context),
                              child: Slider(
                                value: _days.toDouble(),
                                min: 2,
                                max: 21,
                                divisions: 19,
                                onChanged: (v) =>
                                    setState(() => _days = v.round()),
                              ),
                            ),
                          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // Start Date
                          _buildSectionCard(
                            title: AppStrings.startDateTitle,
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now().add(const Duration(days: 14)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 730)),
                                );
                                if (picked != null) {
                                  setState(() => _startDate = picked);
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.glass,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _startDate != null
                                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                          : AppStrings.startDateHint,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: _startDate != null
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_month_rounded,
                                      color: AppColors.accentAmber,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // Budget
                          _buildSectionCard(
                            title: AppStrings.planBudget,
                            child: Row(
                              children: _budgets.map((b) {
                                final (id, label, symbol, desc) = b;
                                final isSelected = _budget == id;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _budget = id),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.accentAmber
                                                .withValues(alpha: 0.12)
                                            : AppColors.glass,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.accentAmber
                                              : AppColors.border,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            symbol,
                                            style: AppTextStyles.dataMedium
                                                .copyWith(
                                              color: isSelected
                                                  ? AppColors.accentAmber
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            label,
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              color: isSelected
                                                  ? AppColors.accentAmber
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // Travel styles
                          _buildSectionCard(
                            title: AppStrings.planTravelStyle,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _travelStyles.map((s) {
                                final (id, label, emoji) = s;
                                final isSelected = _styles.contains(id);
                                return _buildStyleChip(
                                    id, label, emoji, isSelected);
                              }).toList(),
                            ),
                          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // Travelers
                          _buildSectionCard(
                            title: AppStrings.planTravelers,
                            child: Column(
                              children: [
                                _buildStepper(
                                  label: AppStrings.planAdults,
                                  value: _adults,
                                  min: 1,
                                  onChange: (v) => setState(() => _adults = v),
                                ),
                                const SizedBox(height: 12),
                                _buildStepper(
                                  label: AppStrings.planChildren,
                                  value: _children,
                                  min: 0,
                                  onChange: (v) =>
                                      setState(() => _children = v),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        ],
                      ),
                    ),

                    // Bottom CTA
                    _buildBottomCTA(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIGreeting() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.accentAmber.withValues(alpha: 0.3),
                AppColors.accentTurquoise.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: const Center(
            child: Text('🤖', style: TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Text(
              AppStrings.planAIGreeting,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1);
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.titleMedium),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCityChip(String city) {
    final isSelected = _destinationCtrl.text == city;
    return GestureDetector(
      onTap: () => setState(() => _destinationCtrl.text = city),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentAmber.withValues(alpha: 0.15)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.accentAmber : AppColors.border,
          ),
        ),
        child: Text(
          city,
          style: AppTextStyles.chip.copyWith(
            color: isSelected ? AppColors.accentAmber : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStyleChip(
      String id, String label, String emoji, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _styles.remove(id);
          } else {
            _styles.add(id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentAmber.withValues(alpha: 0.15)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.accentAmber : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.chip.copyWith(
                color: isSelected
                    ? AppColors.accentAmber
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required int min,
    required void Function(int) onChange,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            )),
        Row(
          children: [
            _stepperBtn(
              icon: Icons.remove_rounded,
              onTap: value > min ? () => onChange(value - 1) : null,
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppTextStyles.dataMedium,
              ),
            ),
            _stepperBtn(
              icon: Icons.add_rounded,
              onTap: () => onChange(value + 1),
              filled: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepperBtn({
    required IconData icon,
    VoidCallback? onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? AppColors.accentAmber
              : onTap == null
                  ? AppColors.glass.withValues(alpha: 0.3)
                  : AppColors.glass,
          border: filled ? null : Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled
              ? AppColors.bgPrimary
              : onTap == null
                  ? AppColors.textSecondary.withValues(alpha: 0.3)
                  : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: GradientButton(
        label: AppStrings.planGenerateButton,
        icon: Icons.auto_awesome_rounded,
        onPressed: _generate,
      ),
    );
  }

  void _generate() {
    if (_destinationCtrl.text.trim().isEmpty) return;
    // Navigate to generating screen (which runs the AI generation)
    context.push('/plan/generating', extra: {
      'destination': _destinationCtrl.text.trim(),
      'durationDays': _days,
      'budgetTier': _budget,
      'travelStyles': _styles.toList(),
      'travelersCount': _adults + _children,
      'startDate': _startDate,
    });
  }
}

```
