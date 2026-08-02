import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class CloudSyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  StreamSubscription<List<ConnectivityResult>>? _autoSyncSub;

  /// Safe getter — يُرجع null إذا لم يكن Firebase مهيّأً
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Safe getter — يُرجع null إذا لم يكن Firebase مهيّأً
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Starts a connection-change listener for the app's lifetime — call once
  /// at startup. Sync attempts that failed while offline (the only failure
  /// mode `syncTripToCloud`'s silent catch previously left unrecovered) get
  /// retried the moment connectivity comes back, instead of being lost until
  /// some unrelated later event happens to touch the same trip again.
  void startAutoSync() {
    _autoSyncSub?.cancel();
    _autoSyncSub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) syncPendingTrips();
    });
  }

  /// Syncs a single trip, along with all its days, stops, restaurants, and budget items
  /// to Firestore under the `/users/{uid}/trips/{tripId}` document.
  Future<void> syncTripToCloud(String tripId) async {
    try {
      // 0. Guard — تحقق من تهيئة Firebase
      final auth = _auth;
      final firestore = _firestore;
      if (auth == null || firestore == null) return;

      // 1. Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none)) {
        return;
      }

      // 2. Check authenticated user
      final user = auth.currentUser;
      if (user == null || user.isAnonymous) {
        return; // Only sync authenticated users
      }

      // 3. Query local SQLite database for the trip and all associated tables
      final tripRow = await _dbHelper.queryOne('trips', where: 'id = ?', whereArgs: [tripId]);
      if (tripRow == null) return;

      final docRef = firestore.collection('users').doc(user.uid).collection('trips').doc(tripId);

      // 3b. Conflict check — if another device already pushed a newer edit
      // of this trip to the cloud than what this device has locally,
      // overwriting it here would silently discard that edit. Pull the
      // newer cloud version into local instead of pushing over it; this
      // device's version will simply be considered stale (it never had a
      // chance to diverge further since we're about to catch up to cloud).
      final cloudSnap = await docRef.get();
      if (cloudSnap.exists) {
        final cloudData = cloudSnap.data();
        final cloudUpdatedAt =
            DateTime.tryParse(cloudData?['updated_at'] as String? ?? '');
        final localUpdatedAt =
            DateTime.tryParse(tripRow['updated_at'] as String? ?? '');
        if (cloudData != null &&
            cloudUpdatedAt != null &&
            localUpdatedAt != null &&
            cloudUpdatedAt.isAfter(localUpdatedAt)) {
          debugPrint(
              '[CloudSync] Cloud has a newer edit of trip $tripId — pulling instead of overwriting it');
          await _applyCloudTripToLocal(cloudData);
          return;
        }
      }

      final daysRows = await _dbHelper.query('days', where: 'trip_id = ?', whereArgs: [tripId]);
      final stopsRows = await _dbHelper.query('stops', where: 'trip_id = ?', whereArgs: [tripId]);
      final restaurantsRows = await _dbHelper.query('restaurants', where: 'trip_id = ?', whereArgs: [tripId]);
      final hotelsRows = await _dbHelper.query('hotels', where: 'trip_id = ?', whereArgs: [tripId]);
      final budgetItemsRows = await _dbHelper.query('budget_items', where: 'trip_id = ?', whereArgs: [tripId]);
      final chatMessagesRows = await _dbHelper.query('chat_messages', where: 'trip_id = ?', whereArgs: [tripId]);
      final actualExpensesRows = await _dbHelper.query('actual_expenses', where: 'trip_id = ?', whereArgs: [tripId]);
      final documentsRows = await _dbHelper.query('trip_documents', where: 'trip_id = ?', whereArgs: [tripId]);

      // 4. Construct payload (ensuring the user_id matches the active user uid)
      final Map<String, dynamic> tripData = Map<String, dynamic>.from(tripRow);
      tripData['user_id'] = user.uid;

      final Map<String, dynamic> payload = {
        ...tripData,
        'days': daysRows,
        'stops': stopsRows,
        'restaurants': restaurantsRows,
        'hotels': hotelsRows,
        'budget_items': budgetItemsRows,
        'chat_messages': chatMessagesRows,
        'actual_expenses': actualExpensesRows,
        // Only the record (title/type/notes/expiry) travels to the cloud —
        // `file_path` points at a local file on THIS device and won't
        // resolve on another one; only `file_url` (a hosted copy, if any)
        // would still work after a restore.
        'trip_documents': documentsRows,
        'synced_at': DateTime.now().toIso8601String(),
      };

      // 5. Upload to Firestore
      await docRef.set(payload, SetOptions(merge: true));

      // 6. Update local SQLite DB synced_at and user_id fields
      final nowStr = DateTime.now().toIso8601String();
      await _dbHelper.update(
        'trips',
        {'synced_at': nowStr, 'user_id': user.uid},
        where: 'id = ?',
        whereArgs: [tripId],
      );
    } catch (e) {
      // Fail silently to avoid interrupting the user's flow
      debugPrint('CloudSyncService: Error syncing trip $tripId: $e');
    }
  }

  /// Deletes a trip document from Firestore when it is deleted locally.
  Future<void> deleteTripFromCloud(String tripId) async {
    try {
      // Guard — تحقق من تهيئة Firebase
      final auth = _auth;
      final firestore = _firestore;
      if (auth == null || firestore == null) return;

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none)) {
        return;
      }

      final user = auth.currentUser;
      if (user == null || user.isAnonymous) return;

      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(tripId)
          .delete();

      // Confirmed gone from the cloud — the tombstone has done its job, so
      // stop carrying it forever. If this delete never runs (offline, app
      // killed) or fails, the row stays and restoreTripsFromCloud() both
      // keeps skipping the trip and keeps retrying this same delete.
      await _dbHelper.delete('deleted_trip_ids', where: 'trip_id = ?', whereArgs: [tripId]);
    } catch (e) {
      debugPrint('CloudSyncService: Error deleting trip $tripId from cloud: $e');
    }
  }

  /// Fetches raw trip documents from Firestore for a given user.
  Future<List<Map<String, dynamic>>> fetchTripsFromCloud(String uid) async {
    try {
      // Guard — تحقق من تهيئة Firebase
      final firestore = _firestore;
      if (firestore == null) return [];

      final querySnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('trips')
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('CloudSyncService: Error fetching trips from cloud: $e');
      return [];
    }
  }

  /// Downloads all user trips from Firestore and populates the local SQLite tables.
  /// This ensures that when a user reinstalls the app or uses a new device, their data is restored.
  ///
  /// A trip that already exists locally is only overwritten when the cloud
  /// copy is genuinely newer (`updated_at` comparison) — previously this
  /// skipped every already-existing trip unconditionally, so a newer edit
  /// made on another device could never reach this one.
  Future<void> restoreTripsFromCloud(String uid) async {
    try {
      final cloudTrips = await fetchTripsFromCloud(uid);
      final deletedIds = (await _dbHelper.query('deleted_trip_ids'))
          .map((row) => row['trip_id'] as String)
          .toSet();
      var restoredCount = 0;
      var skippedCount = 0;
      var tombstonedCount = 0;

      for (final tripData in cloudTrips) {
        // Isolated per trip — one malformed/legacy cloud document (missing
        // id, a field sqflite can't bind, etc.) must not abort restoration
        // of every trip after it in this batch.
        try {
          final tripId = tripData['id'] as String?;
          if (tripId == null || tripId.isEmpty) {
            skippedCount++;
            debugPrint('CloudSyncService: Skipping a cloud trip with no id');
            continue;
          }

          // Deliberately deleted locally — a cloud copy still existing here
          // means that deletion's fire-and-forget Firestore call never
          // finished (app closed too soon, was offline, etc.). Never
          // resurrect it, and take the opportunity to retry the delete so
          // this stops recurring on every future launch.
          if (deletedIds.contains(tripId)) {
            tombstonedCount++;
            unawaited(deleteTripFromCloud(tripId));
            continue;
          }

          final localTrip = await _dbHelper.queryOne('trips', where: 'id = ?', whereArgs: [tripId]);
          if (localTrip != null) {
            final localUpdatedAt = DateTime.tryParse(localTrip['updated_at'] as String? ?? '');
            final cloudUpdatedAt = DateTime.tryParse(tripData['updated_at'] as String? ?? '');
            final cloudIsNewer = cloudUpdatedAt != null &&
                (localUpdatedAt == null || cloudUpdatedAt.isAfter(localUpdatedAt));
            // Local is already the freshest copy — it'll reach the cloud via
            // syncPendingTrips instead of being overwritten here.
            if (!cloudIsNewer) continue;
          }

          await _applyCloudTripToLocal(tripData);
          restoredCount++;
        } catch (e) {
          skippedCount++;
          debugPrint('CloudSyncService: Failed to restore one cloud trip (skipped, continuing with the rest): $e');
        }
      }

      if (skippedCount > 0 || tombstonedCount > 0) {
        debugPrint(
            'CloudSyncService: restoreTripsFromCloud — $restoredCount restored, $skippedCount skipped, $tombstonedCount tombstoned (deleted locally, retried cloud cleanup)');
      }
    } catch (e) {
      debugPrint('CloudSyncService: Error restoring trips from cloud: $e');
    }
  }

  /// Pushes every trip whose local edits haven't reached the cloud yet
  /// (`synced_at` missing or older than `updated_at`) — call on sign-in and
  /// whenever connectivity comes back (see [startAutoSync]) so a sync that
  /// failed while offline eventually completes instead of being lost.
  Future<void> syncPendingTrips() async {
    try {
      final auth = _auth;
      if (auth == null) return;
      final user = auth.currentUser;
      if (user == null || user.isAnonymous) return;

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none)) {
        return;
      }

      final pending = await _dbHelper.query(
        'trips',
        where: '(synced_at IS NULL OR updated_at > synced_at) AND user_id = ?',
        whereArgs: [user.uid],
      );
      for (final row in pending) {
        await syncTripToCloud(row['id'] as String);
      }
    } catch (e) {
      debugPrint('CloudSyncService: Error syncing pending trips: $e');
    }
  }

  /// Inserts/overwrites a trip and all its nested tables locally from a cloud
  /// document — shared by [restoreTripsFromCloud] and the conflict-pull path
  /// in [syncTripToCloud].
  Future<void> _applyCloudTripToLocal(Map<String, dynamic> tripData) async {
    await _dbHelper.executeInTransaction((txn) async {
      // Extract nested tables
      final List<dynamic> days = tripData['days'] as List<dynamic>? ?? [];
      final List<dynamic> stops = tripData['stops'] as List<dynamic>? ?? [];
      final List<dynamic> restaurants = tripData['restaurants'] as List<dynamic>? ?? [];
      final List<dynamic> hotels = tripData['hotels'] as List<dynamic>? ?? [];
      final List<dynamic> budgetItems = tripData['budget_items'] as List<dynamic>? ?? [];
      final List<dynamic> chatMessages = tripData['chat_messages'] as List<dynamic>? ?? [];
      final List<dynamic> actualExpenses = tripData['actual_expenses'] as List<dynamic>? ?? [];
      final List<dynamic> documents = tripData['trip_documents'] as List<dynamic>? ?? [];

      // Remove nested fields to insert the base trip row
      final Map<String, dynamic> tripRow = Map<String, dynamic>.from(tripData)
        ..remove('days')
        ..remove('stops')
        ..remove('restaurants')
        ..remove('hotels')
        ..remove('budget_items')
        ..remove('chat_messages')
        ..remove('actual_expenses')
        ..remove('trip_documents');

      // Insert trip
      await txn.insert('trips', tripRow, conflictAlgorithm: ConflictAlgorithm.replace);

      // Insert days
      for (final d in days) {
        if (d is Map<String, dynamic>) {
          await txn.insert('days', d, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert stops
      for (final s in stops) {
        if (s is Map<String, dynamic>) {
          await txn.insert('stops', s, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert restaurants
      for (final r in restaurants) {
        if (r is Map<String, dynamic>) {
          await txn.insert('restaurants', r, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert hotels
      for (final h in hotels) {
        if (h is Map<String, dynamic>) {
          await txn.insert('hotels', h, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert budget items
      for (final b in budgetItems) {
        if (b is Map<String, dynamic>) {
          await txn.insert('budget_items', b, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert chat messages
      for (final c in chatMessages) {
        if (c is Map<String, dynamic>) {
          await txn.insert('chat_messages', c, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert actual expenses
      for (final e in actualExpenses) {
        if (e is Map<String, dynamic>) {
          await txn.insert('actual_expenses', e, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert documents (metadata only — see the note where these are read)
      for (final d in documents) {
        if (d is Map<String, dynamic>) {
          await txn.insert('trip_documents', d, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  /// Marks [tripId] as freshly edited and pushes it to the cloud.
  ///
  /// `syncTripToCloud`/`syncPendingTrips` only re-upload a trip that's
  /// already flagged via `updated_at` — a write to a trip's child data
  /// (an expense, a stop's visited flag, a chat command, a document) has to
  /// call this afterwards or that edit would never reach the cloud at all.
  /// Callers use this fire-and-forget, matching every other sync call site.
  Future<void> markTripDirtyAndSync(String tripId) async {
    try {
      await _dbHelper.update(
        'trips',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [tripId],
      );
    } catch (e) {
      debugPrint('CloudSyncService: Failed to mark trip $tripId dirty: $e');
      return;
    }
    await syncTripToCloud(tripId);
  }
}
