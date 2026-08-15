import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/cloud_sync_service.dart';
import '../../nearby/data/nearby_service.dart';
import '../domain/trip_command.dart';

/// Preference order of nearby-place types for each stop category, used to
/// pick the closest-in-kind replacement rather than just the nearest place
/// of any type. Built from the categories in `category_ui.dart` and the
/// `NearbyPlace.type` values the server actually returns.
const _kSwapPreferredTypes = {
  'museum': ['museum', 'historic'],
  'restaurant': ['restaurant', 'cafe'],
  'park': ['park'],
  'shopping': ['shopping'],
  'landmark': ['attraction', 'historic'],
  'beach': ['park', 'other'],
  'mosque': ['worship'],
  'palace': ['attraction', 'historic', 'museum'],
  'market': ['shopping'],
  'viewpoint': ['viewpoint', 'attraction'],
  'other': ['attraction', 'other'],
};

/// The reverse mapping, used to classify the chosen replacement place back
/// into a stop category once it has been picked.
const _kNearbyTypeToStopCategory = {
  'museum': 'museum',
  'restaurant': 'restaurant',
  'cafe': 'restaurant',
  'park': 'park',
  'shopping': 'shopping',
  'attraction': 'landmark',
  'historic': 'landmark',
  'viewpoint': 'viewpoint',
  'worship': 'mosque',
  'other': 'other',
};

/// What a command would do, resolved against the real trip — so the user can be
/// shown exactly what is about to change *before* anything is written.
class TripCommandPreview {
  final TripCommand command;

  /// The trip this command applies to — needed by [TripCommandExecutor.apply]
  /// to sync the right trip to the cloud after the write.
  final String tripId;

  /// Human-readable description of the resolved target ("اليوم 3 · 4 محطات").
  final String targetLabel;

  /// Row ids the command would touch.
  final List<String> affectedIds;

  /// Set when the command can't be carried out (nothing matched, ambiguous…).
  final String? problem;

  /// The real replacement place found for [TripCommandKind.swapStop]. Always
  /// non-null when that command has [problem] == null.
  final SwapCandidate? swapCandidate;

  const TripCommandPreview({
    required this.command,
    required this.tripId,
    required this.targetLabel,
    required this.affectedIds,
    this.problem,
    this.swapCandidate,
  });

  bool get canRun => problem == null && affectedIds.isNotEmpty;

  bool get isDestructive =>
      command.kind == TripCommandKind.deleteDay ||
      command.kind == TripCommandKind.deleteStop ||
      command.kind == TripCommandKind.swapStop;
}

/// Resolves and applies itinerary commands.
///
/// Split deliberately into [preview] and [apply]: nothing is ever written
/// during preview, so the UI can require an explicit confirmation in between.
/// Deletions are irreversible here, which is exactly why they never happen on
/// the strength of a parsed sentence alone.
class TripCommandExecutor {
  final DatabaseHelper _dbHelper;
  final CloudSyncService _syncService;
  final NearbyService _nearbyService;

  TripCommandExecutor({
    DatabaseHelper? dbHelper,
    CloudSyncService? syncService,
    NearbyService? nearbyService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _syncService = syncService ?? CloudSyncService(),
        _nearbyService = nearbyService ?? NearbyService();

  Future<TripCommandPreview> preview({
    required String tripId,
    required TripCommand command,
  }) async {
    try {
      switch (command.kind) {
        case TripCommandKind.deleteDay:
          return _previewDeleteDay(tripId, command);
        case TripCommandKind.deleteStop:
        case TripCommandKind.markVisited:
          return _previewStop(tripId, command);
        case TripCommandKind.swapStop:
          return _previewSwap(tripId, command);
      }
    } catch (e) {
      debugPrint('[TripCommand] preview failed: $e');
      return TripCommandPreview(
        command: command,
        tripId: tripId,
        targetLabel: '',
        affectedIds: const [],
        problem: 'error',
      );
    }
  }

  Future<TripCommandPreview> _previewDeleteDay(
      String tripId, TripCommand command) async {
    final days = await _dbHelper.query(
      'days',
      where: 'trip_id = ? AND day_number = ?',
      whereArgs: [tripId, command.dayNumber],
    );
    if (days.isEmpty) {
      return TripCommandPreview(
        command: command,
        tripId: tripId,
        targetLabel: '${command.dayNumber}',
        affectedIds: const [],
        problem: 'not-found',
      );
    }
    final dayId = days.first['id'] as String;
    final stops = await _dbHelper
        .query('stops', where: 'day_id = ?', whereArgs: [dayId]);
    return TripCommandPreview(
      command: command,
      tripId: tripId,
      targetLabel: '${command.dayNumber}|${stops.length}',
      affectedIds: [dayId],
    );
  }

  Future<TripCommandPreview> _previewStop(
      String tripId, TripCommand command) async {
    final target = command.target;
    if (target == null) {
      // Defense in depth: parseTripCommand never builds a deleteStop/
      // markVisited command with a null target today (it returns null for
      // the whole command instead) — but nothing at the type level enforces
      // that. An explicit guard here means a future change (a new parser, a
      // different TripCommand(...) call site) fails safely instead of
      // throwing.
      return TripCommandPreview(
        command: command,
        tripId: tripId,
        targetLabel: '',
        affectedIds: const [],
        problem: 'error',
      );
    }

    final stops = await _dbHelper
        .query('stops', where: 'trip_id = ?', whereArgs: [tripId]);

    final matches = _matchStopsByName(stops, target);

    if (matches.isEmpty) {
      return TripCommandPreview(
        command: command,
        tripId: tripId,
        targetLabel: target,
        affectedIds: const [],
        problem: 'not-found',
      );
    }
    // More than one place matches: acting on the wrong one is worse than
    // asking the user to be specific.
    if (matches.length > 1) {
      return TripCommandPreview(
        command: command,
        tripId: tripId,
        targetLabel: matches.map((m) => m['name'] as String).join('، '),
        affectedIds: const [],
        problem: 'ambiguous',
      );
    }

    return TripCommandPreview(
      command: command,
      tripId: tripId,
      targetLabel: matches.first['name'] as String,
      affectedIds: [matches.first['id'] as String],
    );
  }

  /// Stops whose name (Arabic or English) fuzzy-matches [target] in either
  /// direction — shared by [_previewStop] and [_previewSwap] so "find the
  /// stop the user means" has one implementation.
  List<Map<String, dynamic>> _matchStopsByName(
      List<Map<String, dynamic>> stops, String target) {
    final query = target.toLowerCase();
    return stops.where((s) {
      final name = ((s['name'] as String?) ?? '').toLowerCase();
      final nameEn = ((s['name_en'] as String?) ?? '').toLowerCase();
      return name.contains(query) ||
          query.contains(name) ||
          (nameEn.isNotEmpty && (nameEn.contains(query) || query.contains(nameEn)));
    }).toList();
  }

  Future<TripCommandPreview> _previewSwap(
      String tripId, TripCommand command) async {
    final target = command.target;
    if (target == null) {
      return TripCommandPreview(
        command: command,
        tripId: tripId,
        targetLabel: '',
        affectedIds: const [],
        problem: 'error',
      );
    }

    final stops = await _dbHelper
        .query('stops', where: 'trip_id = ?', whereArgs: [tripId]);
    final matches = _matchStopsByName(stops, target);

    if (matches.isEmpty) {
      return TripCommandPreview(
        command: command,
        tripId: tripId,
        targetLabel: target,
        affectedIds: const [],
        problem: 'not-found',
      );
    }
    if (matches.length > 1) {
      return TripCommandPreview(
        command: command,
        tripId: tripId,
        targetLabel: matches.map((m) => m['name'] as String).join('، '),
        affectedIds: const [],
        problem: 'ambiguous',
      );
    }

    final oldStop = matches.first;
    final oldName = oldStop['name'] as String;
    final oldLat = (oldStop['latitude'] as num?)?.toDouble() ?? 0.0;
    final oldLng = (oldStop['longitude'] as num?)?.toDouble() ?? 0.0;
    final hasValidLocation = oldLat.abs() > 0.001 && oldLng.abs() > 0.001;
    if (!hasValidLocation) {
      // No real search center to look around — searching from (0,0) would
      // surface places on the wrong continent.
      return TripCommandPreview(
        command: command,
        tripId: tripId,
        targetLabel: oldName,
        affectedIds: const [],
        problem: 'error',
      );
    }

    final nearby = await _nearbyService.getNearby(lat: oldLat, lng: oldLng);

    // Never "replace" a stop with itself or with somewhere already on the
    // itinerary.
    final existingNames = stops
        .map((s) => ((s['name'] as String?) ?? '').toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();
    final existingPlaceIds = stops
        .map((s) => s['place_id'] as String?)
        .whereType<String>()
        .toSet();
    final candidates = nearby.places.where((p) {
      if (p.placeId != null && existingPlaceIds.contains(p.placeId)) {
        return false;
      }
      return !existingNames.contains(p.name.toLowerCase());
    }).toList();

    if (candidates.isEmpty) {
      return TripCommandPreview(
        command: command,
        tripId: tripId,
        targetLabel: oldName,
        affectedIds: const [],
        problem: 'no-alternative',
      );
    }

    final oldCategory = (oldStop['category'] as String?) ?? 'other';
    final preferredTypes = _kSwapPreferredTypes[oldCategory] ?? const [];
    NearbyPlace? best;
    for (final type in preferredTypes) {
      final ofType = candidates.where((p) => p.type == type).toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
      if (ofType.isNotEmpty) {
        best = ofType.first;
        break;
      }
    }
    best ??= ([...candidates]..sort((a, b) => b.rating.compareTo(a.rating))).first;

    return TripCommandPreview(
      command: command,
      tripId: tripId,
      targetLabel: oldName,
      affectedIds: [oldStop['id'] as String],
      swapCandidate: SwapCandidate(
        name: best.name,
        nameEn: best.nameEn,
        address: best.address,
        category: _kNearbyTypeToStopCategory[best.type] ?? 'other',
        lat: best.lat,
        lng: best.lng,
        placeId: best.placeId,
      ),
    );
  }

  /// Applies a previously previewed command. Returns false if it no longer
  /// applies (the data changed between preview and confirmation).
  Future<bool> apply(TripCommandPreview preview) async {
    if (!preview.canRun) return false;
    try {
      switch (preview.command.kind) {
        case TripCommandKind.deleteDay:
          // Stops cascade via the days foreign key, but delete them explicitly
          // so the result is the same regardless of PRAGMA foreign_keys state.
          // Both deletes run in one transaction — otherwise the app being
          // killed between them leaves an empty day with no stops behind.
          final dayId = preview.affectedIds.first;
          final deletedDays = await _dbHelper.executeInTransaction((txn) async {
            await txn.delete('stops', where: 'day_id = ?', whereArgs: [dayId]);
            return txn.delete('days', where: 'id = ?', whereArgs: [dayId]);
          });
          // 0 rows means the day was already gone by the time this ran (e.g.
          // removed by a cloud sync from another device, or another command,
          // between preview and this confirmation) — nothing to report as
          // successfully applied.
          if (deletedDays == 0) return false;
          unawaited(_syncService.markTripDirtyAndSync(preview.tripId));
          return true;

        case TripCommandKind.deleteStop:
          final deletedStops = await _dbHelper.delete('stops',
              where: 'id = ?', whereArgs: [preview.affectedIds.first]);
          if (deletedStops == 0) return false;
          unawaited(_syncService.markTripDirtyAndSync(preview.tripId));
          return true;

        case TripCommandKind.markVisited:
          final updatedStops = await _dbHelper.update(
            'stops',
            {'is_visited': 1},
            where: 'id = ?',
            whereArgs: [preview.affectedIds.first],
          );
          if (updatedStops == 0) return false;
          unawaited(_syncService.markTripDirtyAndSync(preview.tripId));
          return true;

        case TripCommandKind.swapStop:
          final oldId = preview.affectedIds.first;
          // Guaranteed non-null: canRun requires problem == null, and
          // _previewSwap never returns problem == null without one.
          final candidate = preview.swapCandidate!;
          // Read the old stop's scheduling fields before the transaction so
          // the new stop keeps its place in the day — the delete+insert
          // itself still happens atomically inside the transaction below.
          final oldRows = await _dbHelper
              .query('stops', where: 'id = ?', whereArgs: [oldId]);
          if (oldRows.isEmpty) return false;
          final oldStop = oldRows.first;

          final deleted = await _dbHelper.executeInTransaction((txn) async {
            final n = await txn
                .delete('stops', where: 'id = ?', whereArgs: [oldId]);
            if (n > 0) {
              await txn.insert('stops', {
                'id': const Uuid().v4(),
                'day_id': oldStop['day_id'],
                'trip_id': preview.tripId,
                'order_index': oldStop['order_index'],
                'name': candidate.name,
                'name_en': candidate.nameEn,
                'category': candidate.category,
                'time_of_day': oldStop['time_of_day'],
                'start_time': oldStop['start_time'],
                'duration_minutes': oldStop['duration_minutes'],
                'latitude': candidate.lat,
                'longitude': candidate.lng,
                'address': candidate.address,
                'cost_usd': 0,
                'ai_tip': null,
                'ai_tip_en': null,
                'booking_required': 0,
                'booking_url': null,
                'image_url': null,
                'coords_verified': 1,
                'place_id': candidate.placeId,
                'is_visited': 0,
              });
            }
            return n;
          });
          if (deleted == 0) return false;
          unawaited(_syncService.markTripDirtyAndSync(preview.tripId));
          return true;
      }
    } catch (e) {
      debugPrint('[TripCommand] apply failed: $e');
      return false;
    }
  }
}
