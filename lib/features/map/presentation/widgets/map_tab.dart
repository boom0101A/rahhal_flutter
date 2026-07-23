import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../../../../shared/widgets/app_badges.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/di/injection.dart';
import '../cubit/map_cubit.dart';
import '../../data/cached_tile_provider.dart';
import '../../data/offline_map_service.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../../shared/widgets/app_error_widget.dart';

class MapTab extends StatelessWidget {
  final String tripId;

  const MapTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapCubit, MapState>(
      builder: (context, state) {
        if (state is MapLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentAmber),
          );
        }
        if (state is MapError) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () => context.read<MapCubit>().loadMapData(tripId),
          );
        }
        if (state is MapReady) {
          return _MapView(state: state, tripId: tripId);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _MapView extends StatefulWidget {
  final MapReady state;
  final String tripId;

  const _MapView({required this.state, required this.tripId});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> with WidgetsBindingObserver {
  late final MapController _mapController;

  LatLng? _userLocation;
  bool _fetchingLocation = false;
  bool _isLocatingUser = false;
  bool _mapReady = false;
  bool _downloadingOffline = false;
  double _offlineProgress = 0;

  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addObserver(this);

    // Use location from Cubit state immediately if available
    if (widget.state.userLocation != null) {
      _userLocation = widget.state.userLocation;
    }

    // Start location fetch after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserLocation();
      _startLocationStream();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchUserLocation();
    }
  }

  void _startLocationStream() {
    if (kIsWeb) return;

    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        _positionSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 20,
          ),
        ).listen((pos) {
          if (mounted) {
            final newLocation = LatLng(pos.latitude, pos.longitude);
            setState(() => _userLocation = newLocation);
            if (_mapReady && _userLocation == null) {
              _mapController.move(newLocation, 14.0);
            }
          }
        }, onError: (e) {
          debugPrint('[MapTab] Position stream error: $e');
        });
      }
    });
  }

  Future<void> _fetchUserLocation() async {
    if (_fetchingLocation) return;
    _fetchingLocation = true;

    try {
      LatLng? position;

      if (kIsWeb) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          final granted = await Geolocator.requestPermission();
          if (granted == LocationPermission.denied ||
              granted == LocationPermission.deniedForever) {
            _fetchingLocation = false;
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          _fetchingLocation = false;
          return;
        }
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 10),
            ),
          );
          position = LatLng(pos.latitude, pos.longitude);
        } catch (e) {
          debugPrint('[MapTab] Web GPS error: $e');
        }
      } else {
        try {
          final loc = await sl<LocationService>().getCurrentLocation();
          if (loc != null) {
            position = LatLng(loc.latitude, loc.longitude);
          }
        } catch (e) {
          debugPrint('[MapTab] Mobile LocationService error: $e');
          try {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 8),
              ),
            );
            position = LatLng(pos.latitude, pos.longitude);
          } catch (_) {}
        }
      }

      if (position != null && mounted) {
        setState(() => _userLocation = position);

        if (_mapReady && widget.state.stops.isEmpty) {
          _mapController.move(position, 14.0);
        }
      }
    } finally {
      _fetchingLocation = false;
    }
  }

  Future<void> _goToMyLocation() async {
    if (_isLocatingUser) return;
    setState(() => _isLocatingUser = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLocatingUser = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).locationPermissionHint),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (mounted) {
        final newLoc = LatLng(position.latitude, position.longitude);
        setState(() {
          _userLocation = newLoc;
          _isLocatingUser = false;
        });
        _mapController.move(newLoc, 15.0);
      }
    } catch (e) {
      debugPrint('[MapTab] _goToMyLocation error: $e');
      if (mounted) setState(() => _isLocatingUser = false);
    }
  }

  /// Pre-download the trip's map tiles for offline use, with a progress
  /// indicator and a summary snackbar.
  Future<void> _downloadOfflineMap() async {
    final stops = widget.state.stops
        .where((s) => s.hasValidLocation)
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (stops.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.offlineMapNoStops)),
      );
      return;
    }

    setState(() {
      _downloadingOffline = true;
      _offlineProgress = 0;
    });
    messenger.showSnackBar(
      SnackBar(content: Text(strings.offlineMapDownloading)),
    );

    final cached = await OfflineMapService.downloadForStops(
      stops,
      onProgress: (done, total) {
        if (mounted && total > 0) {
          setState(() => _offlineProgress = done / total);
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _downloadingOffline = false;
      _offlineProgress = 0;
    });
    messenger.showSnackBar(
      SnackBar(content: Text(strings.offlineMapDone(cached))),
    );
  }

  LatLng _center() {
    final stops = widget.state.filteredStops.isNotEmpty
        ? widget.state.filteredStops
        : widget.state.stops;

    if (stops.isEmpty) {
      return _userLocation ?? const LatLng(25.0, 45.0);
    }

    final avgLat =
        stops.map((s) => s.latitude).reduce((a, b) => a + b) / stops.length;
    final avgLng =
        stops.map((s) => s.longitude).reduce((a, b) => a + b) / stops.length;
    return LatLng(avgLat, avgLng);
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.state.filteredStops;
    final selectedStop = widget.state.selectedStop;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center(),
            initialZoom: 13,
            onMapReady: () {
              setState(() => _mapReady = true);
              if (_userLocation != null && widget.state.stops.isEmpty) {
                _mapController.move(_userLocation!, 14.0);
              }
            },
            onTap: (_, __) => context.read<MapCubit>().clearSelection(),
          ),
          children: [
            _buildTileLayer(),

            if (_userLocation != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _userLocation!,
                    radius: 35,
                    useRadiusInMeter: false,
                    color: const Color(0x222196F3),
                    borderColor: const Color(0x882196F3),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

            if (stops.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: stops
                        .map((s) => LatLng(s.latitude, s.longitude))
                        .toList(),
                    color: AppColors.accentAmber.withValues(alpha: 0.6),
                    strokeWidth: 3,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 40,
                    height: 40,
                    child: _buildUserLocationMarker(),
                  ),
                ...stops.asMap().entries.map((entry) {
                  final i = entry.key;
                  final stop = entry.value;
                  final isSelected = stop.id == widget.state.selectedStopId;
                  return Marker(
                    point: LatLng(stop.latitude, stop.longitude),
                    width: isSelected ? 48 : 36,
                    height: isSelected ? 64 : 52,
                    child: GestureDetector(
                      onTap: () =>
                          context.read<MapCubit>().selectStop(stop.id),
                      child: _buildMarker(i + 1, stop, isSelected),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        if (selectedStop != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _StopBottomCard(
              stop: selectedStop,
              onClose: () => context.read<MapCubit>().clearSelection(),
            ).animate().slideY(begin: 1, end: 0, duration: 300.ms),
          ),

        // Offline map download button (mobile only — web has no disk cache).
        if (!kIsWeb)
          Positioned(
            bottom: selectedStop != null ? 200 : 80,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.adaptiveBgCard(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.adaptiveBorder(context)),
                boxShadow: AppColors.cardShadow,
              ),
              child: IconButton(
                tooltip: AppStrings.of(context).offlineMapDownload,
                onPressed: _downloadingOffline ? null : _downloadOfflineMap,
                icon: _downloadingOffline
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          value: _offlineProgress > 0 ? _offlineProgress : null,
                          color: AppColors.accentTurquoise,
                        ),
                      )
                    : const Icon(
                        Icons.download_for_offline_rounded,
                        color: AppColors.accentTurquoise,
                        size: 24,
                      ),
              ),
            ),
          ),

        Positioned(
          bottom: selectedStop != null ? 140 : 20,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.adaptiveBgCard(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.adaptiveBorder(context)),
              boxShadow: AppColors.cardShadow,
            ),
            child: IconButton(
              onPressed: _isLocatingUser ? null : _goToMyLocation,
              icon: _isLocatingUser
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentAmber,
                      ),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.accentAmber,
                      size: 24,
                    ),
            ),
          ),
        ),

        Positioned(
          top: 16,
          right: 16,
          child: GlassCardStrong(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              AppStrings.of(context).stopsCount(stops.length),
              style: AppTextStyles.labelMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTileLayer() {
    if (kIsWeb) {
      return TileLayer(
        urlTemplate:
            'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
        subdomains: const ['a', 'b', 'c', 'd'],
        userAgentPackageName: 'com.rahhalai.rahhal_flutter',
        maxZoom: 19,
      );
    }
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.rahhalai.rahhal_flutter',
      maxZoom: 19,
      // Disk-cache every viewed tile so the map keeps working offline.
      tileProvider: CachedTileProvider(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Widget _buildUserLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent,
        ),
        child: const Center(
          child: Icon(
            Icons.navigation_rounded,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1200.ms);
  }

  Widget _buildMarker(int number, StopEntity stop, bool isSelected) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 44 : 32,
          height: isSelected ? 44 : 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.accentAmber : AppColors.adaptiveBgCard(context),
            border: Border.all(
              color: AppColors.accentAmber,
              width: isSelected ? 3 : 2,
            ),
            boxShadow:
                isSelected ? AppColors.amberGlowStrong : AppColors.amberGlow,
          ),
          child: Center(
            child: isSelected
                ? const Icon(Icons.location_on_rounded,
                    color: AppColors.bgPrimary, size: 20)
                : Text(
                    '$number',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accentAmber,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        // Pointer triangle
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainter(
            color: isSelected ? AppColors.accentAmber : AppColors.adaptiveBgCard(context),
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _StopBottomCard extends StatelessWidget {
  final StopEntity stop;
  final VoidCallback onClose;

  const _StopBottomCard({required this.stop, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GlassCardStrong(
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(stop.categoryEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stop.displayName(context),
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (stop.address != null)
                        Text(stop.address!,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded,
                      color: AppColors.adaptiveTextSecondary(context), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                PeriodBadge(period: stop.timeOfDay),
                const SizedBox(width: 8),
                Text(AppStrings.of(context).formatDuration(stop.durationMinutes), style: AppTextStyles.labelSmall),
                const SizedBox(width: 8),
                Text(
                  stop.costUsd == 0 ? AppStrings.of(context).free : '~\$${stop.costUsd.toStringAsFixed(0)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accentAmber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

