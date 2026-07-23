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

/// "What's around me now?" — a live discovery screen that uses the user's
/// current GPS position to list nearby attractions, museums, restaurants and
/// parks (OpenStreetMap via the server). Each item deep-links into Google Maps.
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _Status.loading);
    try {
      final loc = await sl<LocationService>().getCurrentLocation();
      if (loc == null) {
        setState(() => _status = _Status.noLocation);
        return;
      }
      _locationLabel = loc.fullLocationDisplay;
      final places = await sl<NearbyService>()
          .getNearby(lat: loc.latitude, lng: loc.longitude);
      if (!mounted) return;
      setState(() {
        _places = places;
        _status = places.isEmpty ? _Status.empty : _Status.ready;
      });
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  static const _filters = [
    'all',
    'attraction',
    'historic',
    'museum',
    'restaurant',
    'cafe',
    'park',
    'shopping',
    'worship',
  ];

  List<NearbyPlace> get _filtered => _filter == 'all'
      ? _places
      : _places.where((p) => p.type == _filter).toList();

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

  IconData _iconFor(String type) => switch (type) {
        'attraction' => Icons.attractions_rounded,
        'historic' => Icons.account_balance_rounded,
        'museum' => Icons.museum_rounded,
        'restaurant' => Icons.restaurant_rounded,
        'cafe' => Icons.local_cafe_rounded,
        'park' => Icons.park_rounded,
        'shopping' => Icons.local_mall_rounded,
        'worship' => Icons.mosque_rounded,
        'viewpoint' => Icons.landscape_rounded,
        _ => Icons.place_rounded,
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
          if (_locationLabel != null && _status == _Status.ready)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded,
                      size: 16, color: AppColors.accentAmber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${strings.nearbyAround} $_locationLabel',
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          if (_status == _Status.ready) _buildFilters(strings),
          Expanded(child: _buildBody(strings)),
        ],
      ),
    );
  }

  Widget _buildFilters(AppStrings strings) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _filters.map((f) {
          final active = _filter == f;
          return GestureDetector(
            onTap: () {
              Haptics.tap();
              setState(() => _filter = f);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accentAmber
                    : AppColors.adaptiveGlass(context),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: active
                        ? AppColors.accentAmber
                        : AppColors.adaptiveBorder(context)),
              ),
              child: Center(
                child: Text(
                  _filterLabel(f, strings),
                  style: AppTextStyles.chip.copyWith(
                      color: active
                          ? AppColors.bgPrimary
                          : AppColors.adaptiveTextSecondary(context)),
                ),
              ),
            ),
          );
        }).toList(),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: items.length,
          itemBuilder: (context, i) => _placeCard(items[i], strings, i),
        );
    }
  }

  Widget _placeCard(NearbyPlace place, AppStrings strings, int index) {
    final name = strings.languageCode == 'en' && place.nameEn.isNotEmpty
        ? place.nameEn
        : place.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(place.type), color: AppColors.accentAmber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(_filterLabel(place.type, strings),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.adaptiveTextSecondary(context))),
                ],
              ),
            ),
            IconButton(
              tooltip: strings.openInMaps,
              icon: const Icon(Icons.directions_rounded,
                  color: AppColors.accentTurquoise),
              onPressed: () {
                Haptics.tap();
                MapLauncherService.openInGoogleMaps(
                  placeName: name,
                  lat: place.lat,
                  lon: place.lng,
                );
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 40 * index), duration: 300.ms);
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
