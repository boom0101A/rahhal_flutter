import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/cloud_sync_service.dart';
import '../domain/trip_command.dart';

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

  const TripCommandPreview({
    required this.command,
    required this.tripId,
    required this.targetLabel,
    required this.affectedIds,
    this.problem,
  });

  bool get canRun => problem == null && affectedIds.isNotEmpty;

  bool get isDestructive =>
      command.kind == TripCommandKind.deleteDay ||
      command.kind == TripCommandKind.deleteStop;
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

  TripCommandExecutor({DatabaseHelper? dbHelper, CloudSyncService? syncService})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _syncService = syncService ?? CloudSyncService();

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

    final query = target.toLowerCase();
    final matches = stops.where((s) {
      final name = ((s['name'] as String?) ?? '').toLowerCase();
      final nameEn = ((s['name_en'] as String?) ?? '').toLowerCase();
      return name.contains(query) ||
          query.contains(name) ||
          (nameEn.isNotEmpty && (nameEn.contains(query) || query.contains(nameEn)));
    }).toList();

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
      }
    } catch (e) {
      debugPrint('[TripCommand] apply failed: $e');
      return false;
    }
  }
}
