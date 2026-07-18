import 'dart:async';
import 'package:flutter/material.dart';
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
  final LocationService _locationService = sl<LocationService>();

  double? _userLat;
  double? _userLng;
  LatLng? _userLocation;
  bool _isLocatingUser = false;
  bool _fetchingLocation = false;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addObserver(this);

    // Initial check from Cubit state if available
    if (widget.state.userLocation != null) {
      _userLocation = widget.state.userLocation;
      _userLat = widget.state.userLocation!.latitude;
      _userLng = widget.state.userLocation!.longitude;
    }

    _fetchUserLocation();
    _listenToLocationUpdates();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      _fetchUserLocation();
    }
  }

  void _listenToLocationUpdates() {
    _serviceStatusSub = Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.enabled) {
        _fetchUserLocation();
      }
    });

    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        _positionSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          if (mounted) {
            setState(() {
              _userLat = pos.latitude;
              _userLng = pos.longitude;
              _userLocation = LatLng(pos.latitude, pos.longitude);
            });
          }
        });
      }
    });
  }

  Future<void> _fetchUserLocation() async {
    if (_fetchingLocation) return;
    _fetchingLocation = true;
    try {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null && mounted) {
        setState(() {
          _userLat = loc.latitude;
          _userLng = loc.longitude;
          _userLocation = LatLng(loc.latitude, loc.longitude);
        });
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
            const SnackBar(
              content: Text('تعذّر الوصول للموقع. فعّل الإذن من الإعدادات.'),
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
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLocatingUser = false;
        });
      }
    } catch (e) {
      debugPrint('Map location error: $e');
      if (mounted) setState(() => _isLocatingUser = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusSub?.cancel();
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  LatLng _center() {
    final stops = widget.state.filteredStops.isNotEmpty
        ? widget.state.filteredStops
        : widget.state.stops;

    if (stops.isEmpty) {
      if (_userLocation != null) {
        return _userLocation!;
      }
      if (_userLat != null && _userLng != null) {
        return LatLng(_userLat!, _userLng!);
      }
      return const LatLng(25.0, 45.0);
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
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center(),
            initialZoom: 13,
            onTap: (_, __) => context.read<MapCubit>().clearSelection(),
          ),
          children: [
            // OSM tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.rahhalai.rahhal_flutter',
              maxZoom: 19,
            ),

            // User Location Pulse Circle Layer
            if (_userLocation != null || (_userLat != null && _userLng != null))
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _userLocation ?? LatLng(_userLat!, _userLng!),
                    radius: 35,
                    useRadiusInMeter: false,
                    color: const Color(0x222196F3),
                    borderColor: const Color(0x662196F3),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

            // Route polyline
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

            // Stop Markers & User Location Marker
            MarkerLayer(
              markers: [
                // User Location Blue Dot Marker
                if (_userLocation != null || (_userLat != null && _userLng != null))
                  Marker(
                    point: _userLocation ?? LatLng(_userLat!, _userLng!),
                    width: 36,
                    height: 36,
                    child: _buildUserLocationMarker(),
                  ),

                // Trip Stop Markers
                ...stops.asMap().entries.map((entry) {
                  final i = entry.key;
                  final stop = entry.value;
                  final isSelected = stop.id == widget.state.selectedStopId;
                  return Marker(
                    point: LatLng(stop.latitude, stop.longitude),
                    width: isSelected ? 48 : 36,
                    height: isSelected ? 64 : 52,
                    child: GestureDetector(
                      onTap: () => context.read<MapCubit>().selectStop(stop.id),
                      child: _buildMarker(i + 1, stop, isSelected),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Selected stop bottom sheet
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

        // Floating Action Button: My Location Button
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

        // Stops count badge
        Positioned(
          top: 16,
          right: 16,
          child: GlassCardStrong(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '${stops.length} محطة',
              style: AppTextStyles.labelMedium,
            ),
          ),
        ),
      ],
    );
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
            color: isSelected ? AppColors.accentAmber : AppColors.bgCard,
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
            color: isSelected ? AppColors.accentAmber : AppColors.bgCard,
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
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 20),
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

