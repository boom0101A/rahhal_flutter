import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/map_launcher_service.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../data/nearby_service.dart';

/// "What's around me now?" — a live discovery screen. It grabs a fast GPS fix
/// (last-known position, so results render immediately), then lists the CLOSEST
/// attractions, mosques, restaurants, markets, groceries and parks around the
/// user, sourced from Google Places (current names). Each item deep-links into
/// Google Maps at its exact listing.
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

enum _Status { loading, ready, empty, noLocation, error }

class _NearbyScreenState extends State<NearbyScreen> {
  _Status _status = _Status.loading;
  List<NearbyPlace> _places = const [];
  String? _locationLabel;
  String _filter = 'all';
  String _lang = 'ar';
  bool _started = false;
  /// Id of the place whose exact Google listing is currently being resolved.
  String? _openingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _lang = AppStrings.of(context).languageCode;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _status = _Status.loading;
      _locationLabel = null;
    });
    try {
      // 1. Fast, coordinates-only fix — renders results without waiting on a
      //    high-accuracy GPS lock or reverse geocoding.
      final pos = await sl<LocationService>().getQuickPosition();
      if (pos == null) {
        if (mounted) setState(() => _status = _Status.noLocation);
        return;
      }

      // 2. Fetch nearby immediately (closest first, localized names).
      final result = await sl<NearbyService>().getNearby(
        lat: pos.latitude,
        lng: pos.longitude,
        lang: _lang,
      );
      if (!mounted) return;
      setState(() {
        _places = result.places;
        _status = result.places.isEmpty ? _Status.empty : _Status.ready;
      });

      // 3. Resolve a friendly location label in the background (non-blocking).
      sl<LocationService>()
          .reverseGeocode(pos.latitude, pos.longitude)
          .then((label) {
        if (mounted) setState(() => _locationLabel = label);
      });
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  static const _filters = [
    'all',
    'restaurant',
    'cafe',
    'shopping',
    'worship',
    'attraction',
    'historic',
    'museum',
    'park',
  ];

  /// When on, keeps only places Google reports as open right now. Places with
  /// UNKNOWN hours are hidden too — the filter promises "open", and a maybe
  /// isn't one. They stay visible whenever the filter is off.
  bool _openNowOnly = false;

  List<NearbyPlace> get _filtered {
    var list = _filter == 'all'
        ? _places
        : _places.where((p) => p.type == _filter).toList();
    if (_openNowOnly) {
      list = list.where((p) => p.openNow == true).toList();
    }
    return list;
  }

  /// Only offer the toggle when at least one place actually reports its state —
  /// otherwise it would look broken (tap it, everything disappears).
  bool get _anyOpenStateKnown => _places.any((p) => p.openNow != null);

  String _filterLabel(String id, AppStrings s) => switch (id) {
        'all' => s.nearbyFilterAll,
        'attraction' => s.nearbyFilterAttractions,
        'historic' => s.nearbyFilterHistoric,
        'museum' => s.nearbyFilterMuseums,
        'restaurant' => s.nearbyFilterRestaurants,
        'cafe' => s.nearbyFilterCafes,
        'park' => s.nearbyFilterParks,
        'shopping' => s.nearbyFilterShopping,
        'worship' => s.nearbyFilterWorship,
        'viewpoint' => s.nearbyFilterViewpoints,
        _ => s.nearbyFilterOther,
      };

  /// One accent color + icon per category, for a coherent, professional look.
  (Color, IconData) _catStyle(String type) => switch (type) {
        'restaurant' => (const Color(0xFFE8734A), Icons.restaurant_rounded),
        'cafe' => (const Color(0xFFB07A3C), Icons.local_cafe_rounded),
        'worship' => (const Color(0xFF3E9A78), Icons.mosque_rounded),
        'shopping' => (const Color(0xFF7E6AD6), Icons.local_mall_rounded),
        'museum' => (const Color(0xFF4A90D9), Icons.museum_rounded),
        'park' => (const Color(0xFF4CAF6E), Icons.park_rounded),
        'attraction' => (AppColors.accentAmber, Icons.attractions_rounded),
        'historic' => (const Color(0xFF9C7B4A), Icons.account_balance_rounded),
        'viewpoint' => (const Color(0xFF3FA9B5), Icons.landscape_rounded),
        _ => (AppColors.accentTurquoise, Icons.place_rounded),
      };

  IconData _filterIcon(String type) => switch (type) {
        'all' => Icons.explore_rounded,
        _ => _catStyle(type).$2,
      };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(strings.nearbyTitle,
            style: Theme.of(context).appBarTheme.titleTextStyle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: strings.refresh,
            onPressed: _status == _Status.loading ? null : _load,
            icon: Icon(Icons.refresh_rounded,
                color: isDark ? Colors.white : const Color(0xFF0D1B2A)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_status == _Status.ready) _buildHeader(strings),
          if (_status == _Status.ready) _buildFilters(strings),
          Expanded(child: _buildBody(strings)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentTurquoise.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.my_location_rounded,
                size: 18, color: AppColors.accentTurquoise),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locationLabel ?? strings.nearbyLocating,
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  strings.nearbyResultsCount(_filtered.length),
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.adaptiveTextSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppStrings strings) {
    // Only offer filters for categories that actually have results.
    final present = _places.map((p) => p.type).toSet();
    final chips =
        _filters.where((f) => f == 'all' || present.contains(f)).toList();
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          if (_anyOpenStateKnown) _buildOpenNowChip(strings),
          ...chips.map((f) {
          final active = _filter == f;
          final color = f == 'all' ? AppColors.accentAmber : _catStyle(f).$1;
          return GestureDetector(
            onTap: () {
              Haptics.tap();
              setState(() => _filter = f);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? color : AppColors.adaptiveGlass(context),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: active ? color : AppColors.adaptiveBorder(context)),
              ),
              child: Row(
                children: [
                  Icon(_filterIcon(f),
                      size: 15,
                      color: active
                          ? Colors.white
                          : AppColors.adaptiveTextSecondary(context)),
                  const SizedBox(width: 6),
                  Text(
                    _filterLabel(f, strings),
                    style: AppTextStyles.chip.copyWith(
                        color: active
                            ? Colors.white
                            : AppColors.adaptiveTextSecondary(context)),
                  ),
                ],
              ),
            ),
          );
          }),
        ],
      ),
    );
  }

  Widget _buildOpenNowChip(AppStrings strings) {
    const color = Color(0xFF3E9A78);
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        setState(() => _openNowOnly = !_openNowOnly);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _openNowOnly ? color : AppColors.adaptiveGlass(context),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
              color: _openNowOnly ? color : AppColors.adaptiveBorder(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded,
                size: 15,
                color: _openNowOnly
                    ? Colors.white
                    : AppColors.adaptiveTextSecondary(context)),
            const SizedBox(width: 6),
            Text(
              strings.nearbyOpenNow,
              style: AppTextStyles.chip.copyWith(
                  color: _openNowOnly
                      ? Colors.white
                      : AppColors.adaptiveTextSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppStrings strings) {
    switch (_status) {
      case _Status.loading:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(6, (_) => const ShimmerStopCard()),
        );
      case _Status.noLocation:
        return _message('📍', strings.nearbyNoLocationTitle,
            strings.nearbyNoLocationSubtitle, strings.retry);
      case _Status.error:
        return _message('⚠️', strings.nearbyErrorTitle,
            strings.nearbyErrorSubtitle, strings.retry);
      case _Status.empty:
        return _message('🔭', strings.nearbyEmptyTitle,
            strings.nearbyEmptySubtitle, strings.refresh);
      case _Status.ready:
        final items = _filtered;
        if (items.isEmpty) {
          return _message('🔍', strings.nearbyEmptyTitle,
              strings.nearbyEmptySubtitle, null);
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          itemCount: items.length,
          itemBuilder: (context, i) => _placeCard(items[i], strings, i),
        );
    }
  }

  Widget _placeCard(NearbyPlace place, AppStrings strings, int index) {
    final name = _lang == 'en' && place.nameEn.isNotEmpty
        ? place.nameEn
        : place.name;
    final (color, icon) = _catStyle(place.type);
    // Walking time is more actionable than raw metres when you're on foot.
    final distance = place.walkLabel(_lang);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // Ignore repeat taps while this card's listing is being resolved.
          onTap: _openingId != null ? null : () => _openMaps(place, name, strings),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.22),
                        color.withValues(alpha: 0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppTextStyles.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(_filterLabel(place.type, strings),
                              style: AppTextStyles.bodySmall.copyWith(
                                  color:
                                      AppColors.adaptiveTextSecondary(context))),
                          if (place.hasRating) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star_rounded,
                                size: 13, color: AppColors.accentAmber),
                            const SizedBox(width: 2),
                            Text(place.rating.toStringAsFixed(1),
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.accentAmber)),
                          ],
                          // Shown only when Google actually knows the state —
                          // an unknown venue gets no badge rather than a
                          // misleading "closed".
                          if (place.openNow != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: (place.openNow!
                                        ? const Color(0xFF3E9A78)
                                        : AppColors.error)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                place.openNow!
                                    ? strings.nearbyOpenNow
                                    : strings.nearbyClosedNow,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: place.openNow!
                                      ? const Color(0xFF3E9A78)
                                      : AppColors.error,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (place.address.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(place.address,
                            style: AppTextStyles.labelSmall.copyWith(
                                color:
                                    AppColors.adaptiveTextSecondary(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (distance.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppColors.accentTurquoise.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(distance,
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.accentTurquoise,
                                fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(height: 6),
                    if (_openingId == place.id)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentTurquoise,
                        ),
                      )
                    else
                      const Icon(Icons.directions_rounded,
                          color: AppColors.accentTurquoise, size: 22),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
        delay: Duration(milliseconds: 35 * index), duration: 280.ms);
  }

  Future<void> _openMaps(
      NearbyPlace place, String name, AppStrings strings) async {
    Haptics.tap();
    // Places sourced from OSM carry no place_id, so MapLauncherService resolves
    // the exact Google listing first — that takes a moment, and without this
    // indicator the tap looks like it did nothing.
    setState(() => _openingId = place.id);
    try {
      await MapLauncherService.openInGoogleMaps(
        placeName: name,
        city: place.address,
        lat: place.lat,
        lon: place.lng,
        placeId: place.placeId,
      );
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  Widget _message(String emoji, String title, String subtitle, String? action) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(title,
                style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(action),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: AppColors.bgPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
