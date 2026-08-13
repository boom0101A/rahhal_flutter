import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../database/database_helper.dart';

/// Assembles the signed-in user's local data (profile, favorites, every
/// trip's full nested data) into one JSON-serializable map for the
/// "export my data" Settings action. Deliberately separate from
/// [CloudSyncService] — that class is working sync code outside this
/// feature's scope, not something to reuse/modify here.
class DataExportService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> buildExport() async {
    // Same source TripRepositoryImpl._currentUid uses — not a passed-in
    // UserEntity, so this matches exactly what the Trips screen itself sees.
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Shouldn't happen (the app always signs in, even as a guest, before
      // Settings is reachable) — same fail-closed behavior as
      // TripRepositoryImpl.getAllTrips: an empty result, never an
      // unfiltered query that could leak another account's data on a
      // shared device.
      return _emptyExport();
    }
    final uid = user.uid;

    final userRow = await _db.queryOne('users', where: 'uid = ?', whereArgs: [uid]);
    final favorites = await _db.query('favorites', where: 'user_id = ?', whereArgs: [uid]);
    final trips = await _db.query(
      'trips',
      where: 'user_id = ?',
      whereArgs: [uid],
      orderBy: 'created_at DESC',
    );

    final tripsOut = <Map<String, dynamic>>[];
    for (final trip in trips) {
      final tripId = trip['id'] as String;
      final documents = await _db.query(
        'trip_documents',
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );
      tripsOut.add({
        ...trip,
        'days': await _db.query('days', where: 'trip_id = ?', whereArgs: [tripId]),
        'stops': await _db.query('stops', where: 'trip_id = ?', whereArgs: [tripId]),
        'restaurants':
            await _db.query('restaurants', where: 'trip_id = ?', whereArgs: [tripId]),
        'hotels': await _db.query('hotels', where: 'trip_id = ?', whereArgs: [tripId]),
        'budget_items':
            await _db.query('budget_items', where: 'trip_id = ?', whereArgs: [tripId]),
        'chat_messages':
            await _db.query('chat_messages', where: 'trip_id = ?', whereArgs: [tripId]),
        'actual_expenses':
            await _db.query('actual_expenses', where: 'trip_id = ?', whereArgs: [tripId]),
        // file_path is a local device path — meaningless in an exported
        // file handed to the user or another device; stripped the same way
        // CloudSyncService.syncTripToCloud already does for cloud sync.
        'trip_documents': documents.map((r) => {...r, 'file_path': null}).toList(),
      });
    }

    return {
      'export_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'account': {'uid': uid, 'email': user.email, 'display_name': user.displayName},
      'profile': userRow,
      'favorites': favorites,
      'trips': tripsOut,
      // deleted_trip_ids deliberately excluded — an internal tombstone
      // table, not user data.
    };
  }

  Map<String, dynamic> _emptyExport() => {
        'export_version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'account': null,
        'profile': null,
        'favorites': const [],
        'trips': const [],
      };
}
