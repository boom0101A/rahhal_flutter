import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/map_launcher_service.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';
import '../../data/today_service.dart';

/// The travel companion: what the traveller should be doing *right now*, what
/// comes next, and how long it takes to get there — with one tap to navigate
/// and one to tick a stop off.
///
/// Everything comes from the local database, so it keeps working with no
/// signal, which is exactly when a traveller needs it most.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  TodaySnapshot? _snapshot;
  bool _loading = true;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // "Now" moves on its own — refresh so the screen doesn't show a stop that
    // finished twenty minutes ago.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _load());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final snapshot = await sl<TodayService>().load();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<void> _markVisited(StopEntity stop) async {
    Haptics.toggle();
    await sl<TodayService>().setVisited(stop.id, true);
    await _load();
  }

  String _hhmm(DateTime? t) => t == null
      ? ''
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(strings.todayTitle,
            style: Theme.of(context).appBarTheme.titleTextStyle),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accentAmber,
        child: _buildBody(strings),
      ),
    );
  }

  Widget _buildBody(AppStrings strings) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentAmber));
    }

    final snap = _snapshot;
    if (snap == null) return _emptyState(strings);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _dayHeader(snap, strings),
        const SizedBox(height: 14),
        if (snap.allDone)
          _allDoneCard(strings)
        else ...[
          if (snap.current != null)
            _stopCard(
              stop: snap.current!,
              label: strings.todayNow,
              accent: AppColors.accentAmber,
              timeText: snap.currentEndsAt == null
                  ? null
                  : strings.todayEndsAt(_hhmm(snap.currentEndsAt)),
              strings: strings,
            ),
          if (snap.current != null && snap.next != null)
            _travelConnector(snap, strings),
          if (snap.next != null)
            _stopCard(
              stop: snap.next!,
              label: strings.todayNext,
              accent: AppColors.accentTurquoise,
              timeText: snap.nextStartsAt == null
                  ? null
                  : strings.todayStartsAt(_hhmm(snap.nextStartsAt)),
              strings: strings,
            ),
        ],
        const SizedBox(height: 18),
        _restOfDay(snap, strings),
      ],
    );
  }

  Widget _dayHeader(TodaySnapshot snap, AppStrings strings) {
    final progress =
        snap.stops.isEmpty ? 0.0 : snap.visitedCount / snap.stops.length;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.todayDayLabel(snap.dayNumber, snap.destination),
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/trip/${snap.tripId}'),
                child: Text(strings.todayOpenTrip,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.accentTurquoise)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.adaptiveBorder(context),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.accentAmber),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.dayProgressLabel(snap.visitedCount, snap.stops.length),
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.adaptiveTextSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _stopCard({
    required StopEntity stop,
    required String label,
    required Color accent,
    required String? timeText,
    required AppStrings strings,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(label,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: accent, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                if (timeText != null)
                  Text(timeText,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.adaptiveTextSecondary(context))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(stop.categoryEmoji,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stop.displayName(context),
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (stop.address != null && stop.address!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(stop.address!,
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.adaptiveTextSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (stop.hasValidLocation)
                  Expanded(
                    child: _action(
                      icon: Icons.directions_rounded,
                      label: strings.nearbyDirections,
                      color: AppColors.accentTurquoise,
                      onTap: () {
                        Haptics.tap();
                        MapLauncherService.openInGoogleMaps(
                          placeName: stop.displayName(context),
                          city: stop.address,
                          lat: stop.latitude,
                          lon: stop.longitude,
                          placeId: stop.placeId,
                        );
                      },
                    ),
                  ),
                if (stop.hasValidLocation) const SizedBox(width: 8),
                Expanded(
                  child: _action(
                    icon: Icons.check_circle_rounded,
                    label: strings.todayMarkVisited,
                    color: AppColors.success,
                    onTap: () => _markVisited(stop),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _travelConnector(TodaySnapshot snap, AppStrings strings) {
    final travel = snap.travelToNext;
    if (travel == null) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 8, left: 8),
      child: Row(
        children: [
          Icon(travel.isWalking ? Icons.directions_walk_rounded : Icons.directions_car_rounded,
              size: 16, color: AppColors.adaptiveTextSecondary(context)),
          const SizedBox(width: 6),
          Text(
            '${travel.isWalking ? strings.travelWalk(travel.minutes) : strings.travelDrive(travel.minutes)} · ${travel.distanceLabel}',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.adaptiveTextSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _restOfDay(TodaySnapshot snap, AppStrings strings) {
    final remaining = snap.stops
        .where((s) => !s.isVisited && s.id != snap.current?.id && s.id != snap.next?.id)
        .toList();
    if (remaining.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.todayRestOfDay,
            style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.adaptiveTextSecondary(context))),
        const SizedBox(height: 8),
        ...remaining.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Text(s.categoryEmoji, style: const TextStyle(fontSize: 17)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.displayName(context),
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (s.startTime != null)
                    Text(s.startTime!,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.adaptiveTextSecondary(context))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _allDoneCard(AppStrings strings) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 42)),
            const SizedBox(height: 10),
            Text(strings.todayAllDone,
                style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  style: AppTextStyles.labelSmall.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(AppStrings strings) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        const Center(child: Text('🧭', style: TextStyle(fontSize: 64))),
        const SizedBox(height: 16),
        Text(strings.todayNoTripTitle,
            style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(strings.todayNoTripSubtitle,
            style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ],
    );
  }
}
