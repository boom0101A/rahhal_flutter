import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/cached_hero_image.dart';
import '../../../../shared/widgets/weather_widget.dart';
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
import '../widgets/share_trip_card.dart';

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
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  List<(IconData, String)> _tabs(BuildContext context) {
    final strings = AppStrings.of(context);
    return [
      (Icons.calendar_today_rounded, strings.tabSchedule),
      (Icons.map_rounded, strings.tabMap),
      (Icons.restaurant_rounded, strings.tabRestaurants),
      (Icons.account_balance_wallet_rounded, strings.tabCost),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _trip = widget.trip;
    _loadTripIfNeeded();
  }

  Future<void> _loadTripIfNeeded() async {
    // If trip was passed via navigation, skip DB call
    if (_trip != null) {
      return;
    }

    final result = await sl<TripRepository>().getTripById(widget.tripId);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.of(context).snackTripNotFound)),
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
      return Scaffold(
        backgroundColor: AppColors.adaptiveBgPrimary(context),
        body: const Center(
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
        backgroundColor: AppColors.adaptiveBgPrimary(context),
        body: NestedScrollView(
          headerSliverBuilder: (ctx, innerIsScrolled) => [
            _buildHeroSliver(ctx, innerIsScrolled),
          ],
          body: Column(
            children: [
              if (_trip?.isMockData == true)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.of(context).mockTripWarning,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ItineraryTab(tripId: widget.tripId, countryCode: _trip?.countryCode),
                    MapTab(tripId: widget.tripId),
                    RestaurantsTab(tripId: widget.tripId),
                    BudgetTab(tripId: widget.tripId, countryCode: _trip?.countryCode),
                  ],
                ),
              ),
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
      backgroundColor: AppColors.adaptiveBgPrimary(context),
      leading: IconButton(
        onPressed: () => context.go('/home'),
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
      ),
      actions: [
        if (_isSharing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentAmber,
              ),
            ),
          )
        else
          IconButton(
            onPressed: _shareTrip,
            icon: const Icon(Icons.share_rounded,
                color: Colors.white, size: 22),
          ),
        IconButton(
          onPressed: () => context.push('/trip/${widget.tripId}/documents'),
          icon: const Icon(Icons.folder_open_rounded,
              color: Colors.white, size: 22),
        ),
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
            Hero(
              tag: 'trip_hero_${widget.tripId}',
              child: CachedHeroImage(
                url: trip?.displayImageUrl ?? '',
                placeholder: () => _buildHeroGradient(),
              ),
            ),

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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                                    color: AppColors.adaptiveGlassStrong(context),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                        color: AppColors.adaptiveGlassBorder(context)),
                                  ),
                                  child: Text(
                                    '${trip.durationDays} ${AppStrings.of(context).planDurationDays}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.adaptiveTextPrimary(context),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Destination
                          Text(
                            trip?.displayDestination(context) ?? '',
                            style: AppTextStyles.displayMedium.copyWith(color: AppColors.adaptiveTextPrimary(context)),
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
                                    text: ' ${AppStrings.of(context).budgetTotal}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trip != null) ...[
                      const SizedBox(width: 12),
                      WeatherWidget(
                        city: trip.destination,
                        countryCode: trip.countryCode,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Stats row + Tab bar
      bottom: PreferredSize(
        // Stats row (~52) + tab bar (44 tab + 12 padding).
        preferredSize: const Size.fromHeight(108),
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
    final strings = AppStrings.of(context);
    final stats = [
      (Icons.calendar_today_rounded, '${trip.durationDays}', strings.planDurationDays),
      (Icons.people_rounded, '${trip.travelersCount}', strings.statsTravelers),
      (
        Icons.account_balance_wallet_rounded,
        '\$${(trip.budgetTotal / trip.durationDays).toStringAsFixed(0)}',
        strings.statsPerDay
      ),
      (Icons.star_rounded, strings.budgetTierName(trip.budgetTier), ''),
    ];

    return Container(
      color: AppColors.adaptiveBgPrimary(context),
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
      color: AppColors.adaptiveBgPrimary(context),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.adaptiveGlass(context),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.adaptiveBorder(context)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.accentAmber,
            borderRadius: BorderRadius.circular(50),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.adaptiveBgPrimary(context),
          unselectedLabelColor: AppColors.adaptiveTextSecondary(context),
          labelStyle: AppTextStyles.tabLabel,
          unselectedLabelStyle: AppTextStyles.tabLabel,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: _tabs(context)
              .map((t) => Tab(
                    height: 44,
                    // Arabic tab titles vary a lot in width; scale down rather
                    // than ellipsize so every label stays fully readable.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        t.$2,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildChatFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () =>
          context.push('/trip/${widget.tripId}/chat', extra: _trip),
      backgroundColor: AppColors.accentAmber,
      elevation: 8,
      shape: const CircleBorder(),
      child: Icon(Icons.smart_toy_rounded,
          color: AppColors.adaptiveBgPrimary(context), size: 26),
    );
  }

  Future<void> _shareTrip() async {
    final trip = _trip;
    if (trip == null) return;

    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final directionality = Directionality.of(context);

    setState(() => _isSharing = true);

    try {
      final bytes = await _screenshotController.captureFromWidget(
        Theme(
          data: theme,
          child: MediaQuery(
            data: mediaQuery,
            child: Directionality(
              textDirection: directionality,
              child: ShareTripCard(trip: trip),
            ),
          ),
        ),
        context: context,
        delay: const Duration(milliseconds: 100),
      );

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/trip_summary_${trip.id}.png').create();
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${strings.appName} — ${trip.displayDestination(context)}\n${strings.appTagline}',
        subject: trip.displayDestination(context),
      );
    } catch (e) {
      debugPrint('Error sharing trip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.errorGeneral),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}
