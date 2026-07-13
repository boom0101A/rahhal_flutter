# ملف كود Dart: lib\features\trip_planner\presentation\screens\trip_dashboard_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../domain/entities/trip_entity.dart';
import '../../../itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../../itinerary/presentation/widgets/itinerary_tab.dart';
import '../../../map/presentation/cubit/map_cubit.dart';
import '../../../map/presentation/widgets/map_tab.dart';
import '../../../restaurants/presentation/cubit/restaurants_cubit.dart';
import '../../../restaurants/presentation/widgets/restaurants_tab.dart';
import '../../../budget/presentation/cubit/budget_cubit.dart';
import '../../../budget/presentation/widgets/budget_tab.dart';
import '../../domain/repositories/trip_repository.dart';

class TripDashboardScreen extends StatefulWidget {
  final String tripId;
  final TripEntity? trip;

  const TripDashboardScreen({
    super.key,
    required this.tripId,
    this.trip,
  });

  @override
  State<TripDashboardScreen> createState() => _TripDashboardScreenState();
}

class _TripDashboardScreenState extends State<TripDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  TripEntity? _trip;

  List<(IconData, String)> get _tabs => [
    (Icons.calendar_today_rounded, AppStrings.tabSchedule),
    (Icons.map_rounded, AppStrings.tabMap),
    (Icons.restaurant_rounded, AppStrings.tabRestaurants),
    (Icons.account_balance_wallet_rounded, AppStrings.tabCost),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _trip = widget.trip;
    _loadTripIfNeeded();
  }

  Future<void> _loadTripIfNeeded() async {
    final result = await sl<TripRepository>().getTripById(widget.tripId);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.snackTripNotFound)),
          );
          context.go('/home');
        }
      },
      (trip) {
        if (mounted) {
          setState(() => _trip = trip);
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_trip == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentAmber),
        ),
      );
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<ItineraryCubit>()..loadItinerary(widget.tripId),
        ),
        BlocProvider(
          create: (_) =>
              sl<MapCubit>()..loadMapData(widget.tripId),
        ),
        BlocProvider(
          create: (_) =>
              sl<RestaurantsCubit>()..loadRestaurants(widget.tripId),
        ),
        BlocProvider(
          create: (_) =>
              sl<BudgetCubit>()..loadBudget(widget.tripId),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: NestedScrollView(
          headerSliverBuilder: (ctx, innerIsScrolled) => [
            _buildHeroSliver(ctx, innerIsScrolled),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              ItineraryTab(tripId: widget.tripId),
              MapTab(tripId: widget.tripId),
              RestaurantsTab(tripId: widget.tripId),
              BudgetTab(tripId: widget.tripId),
            ],
          ),
        ),
        // AI chat FAB
        floatingActionButton: _buildChatFAB(context),
      ),
    );
  }

  Widget _buildHeroSliver(
      BuildContext context, bool innerIsScrolled) {
    final trip = _trip;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.bgPrimary,
      leading: IconButton(
        onPressed: () => context.go('/home'),
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/trip/${widget.tripId}/chat'),
          icon: const Icon(Icons.chat_bubble_outline_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image or gradient
            if (trip?.heroImageUrl != null)
              Image.network(
                trip!.heroImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildHeroGradient(),
              )
            else
              _buildHeroGradient(),

            // Overlay gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0xCC0D1B2A),
                  ],
                ),
              ),
            ),

            // Content overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(
                      children: [
                        const AIBadge(),
                        const SizedBox(width: 8),
                        if (trip != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.glassStrong,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: AppColors.glassBorder),
                            ),
                            child: Text(
                              '${trip.durationDays} ${AppStrings.planDurationDays}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Destination
                    Text(
                      trip?.destination ?? '',
                      style: AppTextStyles.displayMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Budget
                    if (trip != null)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '~\$${trip.budgetTotal.toStringAsFixed(0)}',
                              style: AppTextStyles.amberBold
                                  .copyWith(fontSize: 22),
                            ),
                            TextSpan(
                              text: ' ${AppStrings.budgetTotal}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Stats row + Tab bar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            if (_trip != null) _buildStatsRow(),
            _buildTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2E42), Color(0xFF0D1B2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text('✈️', style: TextStyle(fontSize: 80)),
      ),
    );
  }

  Widget _buildStatsRow() {
    final trip = _trip!;
    final stats = [
      (Icons.calendar_today_rounded, '${trip.durationDays}', AppStrings.planDurationDays),
      (Icons.people_rounded, '${trip.travelersCount}', AppStrings.statsTravelers),
      (
        Icons.account_balance_wallet_rounded,
        '\$${(trip.budgetTotal / trip.durationDays).toStringAsFixed(0)}',
        AppStrings.statsPerDay
      ),
      (Icons.star_rounded, AppStrings.budgetTierName(trip.budgetTier), ''),
    ];

    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: stats.map((s) {
          final (icon, value, label) = s;
          return Expanded(
            child: Column(
              children: [
                Icon(icon, color: AppColors.accentAmber, size: 16),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.dataSmall,
                ),
                Text(
                  label,
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.border),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.accentAmber,
            borderRadius: BorderRadius.circular(50),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.bgPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
          tabs: _tabs
              .map((t) => Tab(
                    height: 36,
                    child: Text(t.$2),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildChatFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () =>
          context.push('/trip/${widget.tripId}/chat'),
      backgroundColor: AppColors.accentAmber,
      elevation: 8,
      shape: const CircleBorder(),
      child: const Icon(Icons.smart_toy_rounded,
          color: AppColors.bgPrimary, size: 26),
    );
  }
}

```
