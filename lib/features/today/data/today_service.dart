import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/travel_estimate.dart';
import '../../trip_planner/domain/entities/stop_entity.dart';

/// Everything the Today screen needs for right now.
class TodaySnapshot {
  final String tripId;
  final String destination;
  final int dayNumber;

  /// All of today's stops, in order.
  final List<StopEntity> stops;

  /// The stop happening at this moment, if any.
  final StopEntity? current;

  /// The next stop that hasn't started yet.
  final StopEntity? next;

  /// When [current] is scheduled to end.
  final DateTime? currentEndsAt;

  /// When [next] is scheduled to start.
  final DateTime? nextStartsAt;

  /// Travel from [current] (or the user) to [next].
  final TravelEstimate? travelToNext;

  const TodaySnapshot({
    required this.tripId,
    required this.destination,
    required this.dayNumber,
    required this.stops,
    this.current,
    this.next,
    this.currentEndsAt,
    this.nextStartsAt,
    this.travelToNext,
  });

  int get visitedCount => stops.where((s) => s.isVisited).length;

  bool get allDone => stops.isNotEmpty && visitedCount == stops.length;
}

/// Finds the trip happening today and works out where the traveller should be
/// right now. Reads straight from SQLite — no network, so it works mid-trip
/// with no signal.
class TodayService {
  final DatabaseHelper _dbHelper;

  TodayService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Returns null when no saved trip covers today.
  Future<TodaySnapshot?> load({DateTime? now}) async {
    final moment = now ?? DateTime.now();
    final today = DateTime(moment.year, moment.month, moment.day);

    try {
      // A day row carries the concrete date, so matching on it also tells us
      // which trip is active — no separate "is this trip running" flag needed.
      final dayRows = await _dbHelper.query('days', orderBy: 'day_number ASC');
      Map<String, dynamic>? todayRow;
      for (final row in dayRows) {
        final dateText = row['date'] as String?;
        if (dateText == null) continue;
        final date = DateTime.tryParse(dateText);
        if (date == null) continue;
        if (DateTime(date.year, date.month, date.day) == today) {
          todayRow = row;
          break;
        }
      }
      if (todayRow == null) return null;

      final tripId = todayRow['trip_id'] as String;
      final trip = await _dbHelper
          .queryOne('trips', where: 'id = ?', whereArgs: [tripId]);
      if (trip == null) return null;

      final stopRows = await _dbHelper.query(
        'stops',
        where: 'day_id = ?',
        whereArgs: [todayRow['id']],
        orderBy: 'order_index ASC',
      );
      final stops = stopRows.map(_stopFromMap).toList();

      final timing = _resolveTiming(stops, moment, today);

      return TodaySnapshot(
        tripId: tripId,
        destination: (trip['destination'] as String?) ?? '',
        dayNumber: (todayRow['day_number'] as int?) ?? 1,
        stops: stops,
        current: timing.current,
        next: timing.next,
        currentEndsAt: timing.currentEndsAt,
        nextStartsAt: timing.nextStartsAt,
        travelToNext: timing.travel,
      );
    } catch (e) {
      debugPrint('[TodayService] load failed: $e');
      return null;
    }
  }

  /// Works out which stop is happening now and which is next, from each stop's
  /// start time and duration. Stops already marked visited are skipped when
  /// choosing "next" — the traveller has moved on regardless of the clock.
  ({
    StopEntity? current,
    StopEntity? next,
    DateTime? currentEndsAt,
    DateTime? nextStartsAt,
    TravelEstimate? travel,
  }) _resolveTiming(List<StopEntity> stops, DateTime now, DateTime today) {
    StopEntity? current;
    StopEntity? next;
    DateTime? currentEndsAt;
    DateTime? nextStartsAt;

    for (final stop in stops) {
      final start = _startOf(stop, today);
      if (start == null) continue;
      final end = start.add(Duration(minutes: stop.durationMinutes));

      if (!stop.isVisited && now.isAfter(start) && now.isBefore(end)) {
        current = stop;
        currentEndsAt = end;
      } else if (start.isAfter(now) && !stop.isVisited) {
        // First future stop wins — the list is already order_index sorted.
        if (next == null) {
          next = stop;
          nextStartsAt = start;
        }
      }
    }

    // Nothing scheduled right now but stops remain: point at the first
    // unvisited one so the screen is never empty mid-trip.
    if (current == null && next == null) {
      for (final stop in stops) {
        if (!stop.isVisited) {
          next = stop;
          nextStartsAt = _startOf(stop, today);
          break;
        }
      }
    }

    TravelEstimate? travel;
    final from = current;
    final to = next;
    if (from != null && to != null) {
      travel = TravelEstimate.between(
        fromLat: from.latitude,
        fromLng: from.longitude,
        toLat: to.latitude,
        toLng: to.longitude,
      );
    }

    return (
      current: current,
      next: next,
      currentEndsAt: currentEndsAt,
      nextStartsAt: nextStartsAt,
      travel: travel,
    );
  }

  /// Combines the stop's "HH:mm" start time with today's date.
  static DateTime? _startOf(StopEntity stop, DateTime today) {
    final raw = stop.startTime;
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour > 23 || minute > 59) return null;
    return DateTime(today.year, today.month, today.day, hour, minute);
  }

  StopEntity _stopFromMap(Map<String, dynamic> m) => StopEntity(
        id: m['id'] as String,
        dayId: m['day_id'] as String,
        tripId: m['trip_id'] as String,
        orderIndex: m['order_index'] as int? ?? 0,
        name: m['name'] as String,
        nameEn: m['name_en'] as String?,
        category: m['category'] as String? ?? 'other',
        timeOfDay: m['time_of_day'] as String? ?? 'morning',
        startTime: m['start_time'] as String?,
        durationMinutes: m['duration_minutes'] as int? ?? 60,
        latitude: (m['latitude'] as num? ?? 0).toDouble(),
        longitude: (m['longitude'] as num? ?? 0).toDouble(),
        address: m['address'] as String?,
        costUsd: (m['cost_usd'] as num? ?? 0).toDouble(),
        aiTip: m['ai_tip'] as String?,
        imageUrl: m['image_url'] as String?,
        bookingRequired: (m['booking_required'] as int? ?? 0) == 1,
        bookingUrl: m['booking_url'] as String?,
        placeId: m['place_id'] as String?,
        isVisited: (m['is_visited'] as int? ?? 0) == 1,
      );

  /// Toggles a stop's visited flag straight from the Today screen.
  Future<void> setVisited(String stopId, bool visited) async {
    await _dbHelper.update(
      'stops',
      {'is_visited': visited ? 1 : 0},
      where: 'id = ?',
      whereArgs: [stopId],
    );
  }
}
