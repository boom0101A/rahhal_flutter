import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/data/iraq_places.dart';

class TripInputScreen extends StatefulWidget {
  const TripInputScreen({super.key});

  @override
  State<TripInputScreen> createState() => _TripInputScreenState();
}

class _TripInputScreenState extends State<TripInputScreen> {
  static const int _maxAdults = 12;
  static const int _maxChildren = 10;

  late final TextEditingController _destinationCtrl;
  late final TextEditingController _targetBudgetCtrl;
  bool _isDetectingLocation = false;
  int _days = 7;
  String _budget = 'mid';
  final Set<String> _styles = {'culture', 'food'};
  int _adults = 2;
  int _children = 0;
  DateTime? _startDate;

  double? _detectedLat;
  double? _detectedLng;
  String? _detectedCountryCode;
  String? _lastAutoFilledText;

  // Guards against a double-tap on "Generate" opening two generating screens
  // at once — each has its own TripPlannerCubit, so that meant two paid AI
  // requests and two identical trips saved.
  bool _isGenerating = false;

  /// Live offline search results for whatever is typed in the destination box.
  List<IraqPlace> _suggestions = const [];

  Future<void> _detectCurrentLocation() async {
    final strings = AppStrings.of(context);
    setState(() => _isDetectingLocation = true);

    try {
      final locationData = await sl<LocationService>().getCurrentLocation();
      if (locationData != null && mounted) {
        setState(() {
          _destinationCtrl.text = locationData.fullLocationDisplay;
          _detectedLat = locationData.latitude;
          _detectedLng = locationData.longitude;
          _detectedCountryCode = locationData.countryCode;
          _lastAutoFilledText = locationData.fullLocationDisplay;
          _isDetectingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).locationDetected(locationData.fullLocationDisplay)),
            backgroundColor: AppColors.accentAmber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        setState(() => _isDetectingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.locationPermissionDenied),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  List<(String, String, String, String)> _budgets(BuildContext context) {
    final strings = AppStrings.of(context);
    return [
      ('economy', strings.planBudgetEconomy, '\$', strings.planBudgetEconomySub),
      ('mid', strings.planBudgetMid, '\$\$', strings.planBudgetMidSub),
      ('luxury', strings.planBudgetLuxury, '\$\$\$', strings.planBudgetLuxurySub),
    ];
  }

  List<(String, String, String)> _travelStyles(BuildContext context) {
    final strings = AppStrings.of(context);
    return [
      ('culture', strings.styleCulture, '🏛️'),
      ('adventure', strings.styleAdventure, '🧭'),
      ('food', strings.styleFood, '🍽️'),
      ('shopping', strings.styleShopping, '🛍️'),
      ('nature', strings.styleNature, '🌿'),
      ('relax', strings.styleRelax, '🌊'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _destinationCtrl = TextEditingController();
    _targetBudgetCtrl = TextEditingController();
    _initDestination();
    _restoreLastSettings();

    _destinationCtrl.addListener(() {
      if (_detectedLat != null) {
        final currentText = _destinationCtrl.text.trim();
        if (currentText != (_lastAutoFilledText ?? '')) {
          setState(() {
            _detectedLat = null;
            _detectedLng = null;
            _detectedCountryCode = null;
          });
        }
      }
    });
  }

  Future<void> _initDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDest = prefs.getString('last_destination');
    if (mounted && lastDest != null && lastDest.isNotEmpty && _destinationCtrl.text.isEmpty) {
      setState(() {
        _destinationCtrl.text = lastDest;
      });
    }
  }

  /// Restores the traveler-preference part of the form (duration, budget
  /// tier, travel styles, party size) from the last successful generation —
  /// the destination itself is intentionally left for the user to type,
  /// since it's the one field that usually differs trip to trip.
  Future<void> _restoreLastSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final days = prefs.getInt('last_duration_days');
    final budget = prefs.getString('last_budget_tier');
    final styles = prefs.getStringList('last_travel_styles');
    final adults = prefs.getInt('last_adults_count');
    final children = prefs.getInt('last_children_count');

    setState(() {
      if (days != null) _days = days.clamp(2, 21);
      if (budget != null) _budget = budget;
      if (styles != null && styles.isNotEmpty) {
        _styles
          ..clear()
          ..addAll(styles);
      }
      if (adults != null) _adults = adults.clamp(1, _maxAdults);
      if (children != null) _children = children.clamp(0, _maxChildren);
    });
  }

  Future<void> _saveLastSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_duration_days', _days);
    await prefs.setString('last_budget_tier', _budget);
    await prefs.setStringList('last_travel_styles', _styles.toList());
    await prefs.setInt('last_adults_count', _adults);
    await prefs.setInt('last_children_count', _children);
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _targetBudgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.adaptiveBgPrimary(context),
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
                            tooltip: strings.back,
                            onPressed: () => context.go('/home'),
                            icon: Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppColors.adaptiveTextPrimary(context), size: 20),
                          ),
                          Expanded(
                            child: Text(
                              strings.planTitle,
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
                          const SizedBox(height: 16),

                          // "What's around me" — live nearby discovery
                          _buildNearbyButton(context),
                          const SizedBox(height: 20),

                          // Destination
                          _buildSectionCard(
                            title: strings.planDestination,
                            trailing: GestureDetector(
                              onTap: _isDetectingLocation ? null : _detectCurrentLocation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentAmber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isDetectingLocation)
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.accentAmber,
                                        ),
                                      )
                                    else
                                      const Icon(Icons.my_location_rounded, size: 14, color: AppColors.accentAmber),
                                    const SizedBox(width: 4),
                                    // Flexible + ellipsis: when the outer
                                    // Flexible above compresses this pill
                                    // below its natural width (long English
                                    // strings on a narrow screen), the text
                                    // truncates instead of overflowing past
                                    // the edge of the screen.
                                    Flexible(
                                      child: Text(
                                        strings.discoverCurrentCityButton,
                                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentAmber),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _destinationCtrl,
                                  style: AppTextStyles.bodyLarge,
                                  onChanged: _onDestinationChanged,
                                  decoration: InputDecoration(
                                    hintText: strings.planDestinationHint,
                                    prefixIcon: Icon(Icons.search_rounded,
                                        color: AppColors.adaptiveTextSecondary(context),
                                        size: 20),
                                    suffixIcon: IconButton(
                                      tooltip: strings.discoverCurrentCityButton,
                                      icon: const Icon(Icons.gps_fixed_rounded, color: AppColors.accentAmber, size: 20),
                                      onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
                                    ),
                                  ),
                                ),
                                // Smart search results — every Iraqi
                                // governorate, city, district and landmark,
                                // matched offline (no API cost, instant).
                                if (_suggestions.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildSuggestions(strings),
                                ],
                                if (_suggestions.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: strings.popularCities
                                        .map((c) => _buildCityChip(c))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // Duration slider
                          _buildSectionCard(
                            title: strings.planDuration,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentAmber
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                '$_days ${strings.planDurationDays}',
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
                            title: strings.startDateTitle,
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
                                  color: AppColors.adaptiveGlass(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.adaptiveBorder(context)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _startDate != null
                                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                          : strings.startDateHint,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                      color: _startDate != null
                                            ? AppColors.adaptiveTextPrimary(context)
                                            : AppColors.adaptiveTextSecondary(context),
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
                            title: strings.planBudget,
                            child: Row(
                              children: _budgets(context).map((b) {
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
                                            : AppColors.adaptiveGlass(context),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.accentAmber
                                              : AppColors.adaptiveBorder(context),
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
                                                  : AppColors.adaptiveTextSecondary(context),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            label,
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              color: isSelected
                                                  ? AppColors.accentAmber
                                                  : AppColors.adaptiveTextSecondary(context),
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
                            title: strings.planTravelStyle,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _travelStyles(context).map((s) {
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
                            title: strings.planTravelers,
                            child: Column(
                              children: [
                                _buildStepper(
                                  label: strings.planAdults,
                                  value: _adults,
                                  min: 1,
                                  max: _maxAdults,
                                  onChange: (v) => setState(() => _adults = v),
                                ),
                                const SizedBox(height: 12),
                                _buildStepper(
                                  label: strings.planChildren,
                                  value: _children,
                                  min: 0,
                                  max: _maxChildren,
                                  onChange: (v) =>
                                      setState(() => _children = v),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // Optional total budget cap
                          _buildSectionCard(
                            title: strings.planTargetBudgetLabel,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _targetBudgetCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: AppTextStyles.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: strings.planTargetBudgetHint,
                                    prefixIcon: Icon(Icons.attach_money_rounded,
                                        color: AppColors.adaptiveTextSecondary(context), size: 20),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  strings.planTargetBudgetHelper,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.adaptiveTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.1),
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
    );
  }

  Widget _buildNearbyButton(BuildContext context) {
    final strings = AppStrings.of(context);
    return GestureDetector(
      onTap: () => context.push('/nearby'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentTurquoise.withValues(alpha: 0.18),
              AppColors.accentAmber.withValues(alpha: 0.12),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.accentTurquoise.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.explore_rounded,
                color: AppColors.accentTurquoise, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.nearbyTitle, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text(strings.nearbyDiscoverSubtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.adaptiveTextSecondary(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.adaptiveTextSecondary(context)),
          ],
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
              AppStrings.of(context).planAIGreeting,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.adaptiveTextPrimary(context),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Expanded so a long trailing control (e.g. the English
              // "Explore My Current City" pill) can never push the title off
              // the edge of the screen — the title wraps instead of
              // overflowing.
              Expanded(
                child: Text(title, style: AppTextStyles.titleMedium),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                // Flexible so trailing itself is also allowed to shrink below
                // its natural width when the row is tight — its own content
                // (below) must in turn know how to truncate under that
                // constraint, or this alone just moves the overflow inward.
                Flexible(child: trailing),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Runs the offline index on every keystroke. Suggestions are hidden once the
  /// field already holds an exact place name (i.e. the user picked one).
  void _onDestinationChanged(String value) {
    final q = value.trim();
    if (q.isEmpty) {
      setState(() => _suggestions = const []);
      return;
    }
    final results = searchIraqPlaces(q);
    final alreadyPicked =
        results.length == 1 && results.first.ar == q;
    setState(() => _suggestions = alreadyPicked ? const [] : results);
  }

  void _pickSuggestion(IraqPlace place) {
    FocusScope.of(context).unfocus();
    setState(() {
      // Always the Arabic name, even when the UI is in English. The server
      // resolves an Arabic name through its zero-cost dictionary and attaches
      // the governorate's real centre coordinates, and those coordinates are
      // the trusted anchor its out-of-governorate stop filter measures against.
      // An English name resolves too, but via a pass-through branch that
      // returns no coordinates — so sending it would quietly disable that
      // filter for every English-language user. The suggestion list is
      // translated instead; see _suggestionTitle.
      _destinationCtrl.text = place.ar;
      _suggestions = const [];
    });
  }

  String _kindLabel(IraqPlaceKind kind, AppStrings s) => switch (kind) {
        IraqPlaceKind.governorate => s.searchKindGovernorate,
        IraqPlaceKind.city => s.searchKindCity,
        IraqPlaceKind.landmark => s.searchKindLandmark,
      };

  /// What the suggestion row shows. The dataset's `en` is the canonical
  /// planner key, which also makes it the best English label available.
  ///
  /// This is display only — [_pickSuggestion] still writes the Arabic name into
  /// the field, and for a real reason: the server resolves an Arabic name
  /// through its dictionary and attaches the governorate's true centre
  /// coordinates, which is what its out-of-governorate stop filter measures
  /// against. An English name takes a pass-through branch with no coordinates,
  /// so the trip would lose that anchor.
  String _suggestionTitle(IraqPlace p, AppStrings s) =>
      s.languageCode == 'en' ? p.en : p.ar;

  String _suggestionSubtitle(IraqPlace p, AppStrings s) {
    final kind = _kindLabel(p.kind, s);
    if (s.languageCode != 'en') return '$kind · ${p.governorate}';
    final gov = governorateEn(p.governorate);
    // Foreign entries store a country name here and have no English row —
    // show the kind alone rather than an Arabic word inside an English UI.
    return gov == null ? kind : '$kind · $gov';
  }

  (IconData, Color) _kindStyle(IraqPlaceKind kind) => switch (kind) {
        IraqPlaceKind.governorate => (Icons.account_balance_rounded, AppColors.accentAmber),
        IraqPlaceKind.city => (Icons.location_city_rounded, AppColors.accentTurquoise),
        IraqPlaceKind.landmark => (Icons.attractions_rounded, Color(0xFF7E6AD6)),
      };

  Widget _buildSuggestions(AppStrings strings) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppColors.adaptiveGlass(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.adaptiveBorder(context)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppColors.adaptiveBorder(context).withValues(alpha: 0.4),
        ),
        itemBuilder: (_, i) {
          final p = _suggestions[i];
          final (icon, color) = _kindStyle(p.kind);
          return InkWell(
            onTap: () => _pickSuggestion(p),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 17, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_suggestionTitle(p, strings),
                            style: AppTextStyles.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          _suggestionSubtitle(p, strings),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.adaptiveTextSecondary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.north_west_rounded,
                      size: 15,
                      color: AppColors.adaptiveTextSecondary(context)),
                ],
              ),
            ),
          );
        },
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
              : AppColors.adaptiveGlass(context),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.accentAmber : AppColors.adaptiveBorder(context),
          ),
        ),
        child: Text(
          city,
          style: AppTextStyles.chip.copyWith(
            color: isSelected ? AppColors.accentAmber : AppColors.adaptiveTextSecondary(context),
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
              : AppColors.adaptiveGlass(context),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.accentAmber : AppColors.adaptiveBorder(context),
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
                    : AppColors.adaptiveTextSecondary(context),
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
    required int max,
    required void Function(int) onChange,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
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
              onTap: value < max ? () => onChange(value + 1) : null,
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
                  ? AppColors.adaptiveGlass(context).withValues(alpha: 0.3)
                  : AppColors.adaptiveGlass(context),
          border: filled ? null : Border.all(color: AppColors.adaptiveBorder(context)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled
              ? AppColors.onAmber
              : onTap == null
                  ? AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.3)
                  : AppColors.adaptiveTextPrimary(context),
        ),
      ),
    );
  }

  Widget _buildBottomCTA() {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBgPrimary(context).withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.adaptiveBorder(context))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientButton(
            label: strings.planGenerateButton,
            icon: Icons.auto_awesome_rounded,
            isLoading: _isGenerating,
            onPressed: _generate,
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    if (_isGenerating) return;
    final destination = _destinationCtrl.text.trim();
    final strings = AppStrings.of(context);

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.validationEmptyDestination),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _destinationCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _destinationCtrl.text.length),
      );
      return;
    }

    if (destination.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.validationShortDestination),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_styles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.validationEmptyStyles),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final targetBudgetText = _targetBudgetCtrl.text.trim();
    double? targetBudgetUsd;
    if (targetBudgetText.isNotEmpty) {
      targetBudgetUsd = double.tryParse(targetBudgetText);
      if (targetBudgetUsd == null || targetBudgetUsd <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.validationInvalidBudget),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // Save last destination and the rest of the form for next time
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('last_destination', destination);
    });
    _saveLastSettings();

    setState(() => _isGenerating = true);

    // Deliberately NOT awaited. The generating screen never pops — it always
    // leaves via `context.go` (to the finished trip, or back to '/plan' on
    // error/cancel), which REPLACES the stack instead of popping. A pushed
    // route removed that way never completes its future, so the previous
    // `await` here hung forever and left this button spinning until the app
    // was killed and relaunched — exactly the stuck spinner that was reported.
    unawaited(context.push('/plan/generating', extra: {
      'destination': destination,
      'durationDays': _days,
      'budgetTier': _budget,
      'travelStyles': _styles.toList(),
      'travelersCount': _adults + _children,
      'startDate': _startDate,
      'userLat': _detectedLat,
      'userLng': _detectedLng,
      'countryCode': _detectedCountryCode,
      'targetBudgetUsd': targetBudgetUsd,
    }));

    // The flag exists only to swallow a double-tap while the push is in
    // flight; the generating screen covers this one immediately, so a short
    // window is enough — and, unlike awaiting, it can never get stuck.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _isGenerating = false);
  }
}
