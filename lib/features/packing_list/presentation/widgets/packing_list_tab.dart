import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../trip_planner/domain/entities/trip_entity.dart';
import '../../domain/entities/packing_item_entity.dart';
import '../cubit/packing_list_cubit.dart';

class PackingListTab extends StatefulWidget {
  final TripEntity trip;

  const PackingListTab({super.key, required this.trip});

  @override
  State<PackingListTab> createState() => _PackingListTabState();
}

class _PackingListTabState extends State<PackingListTab> {
  @override
  void initState() {
    super.initState();
    context.read<PackingListCubit>().loadPackingList(widget.trip.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackingListCubit, PackingListState>(
      builder: (context, state) {
        if (state is PackingListLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentAmber),
          );
        }
        if (state is PackingListError) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () => context
                .read<PackingListCubit>()
                .loadPackingList(widget.trip.id),
          );
        }
        if (state is PackingListLoaded) {
          final items = state.items;
          final totalCount = items.length;
          final packedCount = items.where((i) => i.isPacked).length;
          final progress = totalCount > 0 ? (packedCount / totalCount) : 0.0;

          if (items.isEmpty) {
            return _buildEmptyState(context, state);
          }

          // Group items by category
          final categories = ['clothing', 'toiletries', 'electronics', 'documents', 'other'];
          final groupedItems = <String, List<PackingItemEntity>>{};
          for (final cat in categories) {
            groupedItems[cat] = items.where((i) => i.category == cat).toList();
          }

          return Stack(
            children: [
              Scaffold(
                backgroundColor: Colors.transparent,
                body: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Progress Card
                    _buildProgressCard(context, packedCount, totalCount, progress),
                    const SizedBox(height: 20),

                    // Collapsible or custom category lists
                    ...categories.map((cat) {
                      final catItems = groupedItems[cat] ?? [];
                      if (catItems.isEmpty) return const SizedBox.shrink();
                      return _buildCategorySection(context, cat, catItems);
                    }),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: AppColors.bgPrimary,
                  onPressed: () => _showAddItemBottomSheet(context),
                  child: const Icon(Icons.add_rounded),
                ),
              ),
              if (state.isActionLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.accentAmber),
                  ),
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

  Widget _buildEmptyState(BuildContext context, PackingListLoaded state) {
    final strings = AppStrings.of(context);
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎒', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  strings.packingEmptyState,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: strings.packingGenerateAI,
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () {
                    context.read<PackingListCubit>().generateAIList(
                          tripId: widget.trip.id,
                          destination: widget.trip.destination,
                          durationDays: widget.trip.durationDays,
                          travelStyles: widget.trip.travelStyles,
                        );
                  },
                ),
              ],
            ),
          ),
        ),
        if (state.isActionLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accentAmber),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressCard(
      BuildContext context, int packed, int total, double progress) {
    final strings = AppStrings.of(context);
    final isArabic = strings.languageCode == 'ar';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentAmber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.backpack_rounded, color: AppColors.accentAmber),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic
                          ? '$packed من $total ${strings.packingProgress}'
                          : '$packed of $total ${strings.packingProgress}',
                      style: AppTextStyles.titleMedium,
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.accentAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentAmber,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCategorySection(
      BuildContext context, String cat, List<PackingItemEntity> catItems) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(
            strings.packingCategoryLabel(cat),
            style: AppTextStyles.headlineSmall,
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: catItems.length,
            separatorBuilder: (ctx, idx) => Divider(
              color: Colors.white.withValues(alpha: 0.06),
              height: 1,
            ),
            itemBuilder: (ctx, idx) {
              final item = catItems[idx];
              return _buildPackingItemRow(context, item);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildPackingItemRow(BuildContext context, PackingItemEntity item) {
    final strings = AppStrings.of(context);
    final isArabic = strings.languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        children: [
          Checkbox(
            activeColor: AppColors.accentAmber,
            checkColor: AppColors.bgPrimary,
            value: item.isPacked,
            onChanged: (_) {
              context.read<PackingListCubit>().toggleItemPacked(item);
            },
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      decoration: item.isPacked ? TextDecoration.lineThrough : null,
                      color: item.isPacked ? AppColors.adaptiveTextSecondary(context) : AppColors.adaptiveTextPrimary(context),
                    ),
                  ),
                ),
                if (item.isAiSuggested)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.accentAmber.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.accentAmber, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          isArabic ? 'ذكاء اصطناعي' : 'AI',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accentAmber,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<PackingListCubit>().removeItem(widget.trip.id, item.id);
            },
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.adaptiveTextSecondary(context),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<PackingListCubit>()),
        ],
        child: _AddPackingItemBottomSheet(tripId: widget.trip.id),
      ),
    );
  }
}

class _AddPackingItemBottomSheet extends StatefulWidget {
  final String tripId;

  const _AddPackingItemBottomSheet({required this.tripId});

  @override
  State<_AddPackingItemBottomSheet> createState() => _AddPackingItemBottomSheetState();
}

class _AddPackingItemBottomSheetState extends State<_AddPackingItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _selectedCategory = 'clothing';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final categories = ['clothing', 'toiletries', 'electronics', 'documents', 'other'];

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.packingAddItem,
                    style: AppTextStyles.displaySmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Item Name Field
              Text(strings.packingAddItem, style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: strings.packingItemNameHint,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return strings.errorGeneral;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Wrap
              Text(strings.expenseCategory, style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(strings.packingCategoryLabel(cat)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                    selectedColor: AppColors.accentAmber,
                    backgroundColor: AppColors.adaptiveGlass(context),
                    checkmarkColor: AppColors.bgPrimary,
                    labelStyle: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? AppColors.bgPrimary : AppColors.adaptiveTextPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Submit Button
              GradientButton(
                label: strings.packingAddItem,
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
    context.read<PackingListCubit>().addItem(
          widget.tripId,
          _nameCtrl.text.trim(),
          _selectedCategory,
        );
    Navigator.pop(context);
  }
}
