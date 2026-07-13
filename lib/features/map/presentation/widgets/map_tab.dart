import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../../../../shared/widgets/app_badges.dart';
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

class _MapViewState extends State<_MapView> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _center() {
    final stops = widget.state.filteredStops.isNotEmpty
        ? widget.state.filteredStops
        : widget.state.stops;

    if (stops.isEmpty) {
      return const LatLng(25.0, 45.0); // Better world default center
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

            // Markers
            MarkerLayer(
              markers: stops.asMap().entries.map((entry) {
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
              }).toList(),
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
