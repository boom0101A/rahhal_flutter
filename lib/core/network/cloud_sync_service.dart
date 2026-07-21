import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class CloudSyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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

      final daysRows = await _dbHelper.query('days', where: 'trip_id = ?', whereArgs: [tripId]);
      final stopsRows = await _dbHelper.query('stops', where: 'trip_id = ?', whereArgs: [tripId]);
      final restaurantsRows = await _dbHelper.query('restaurants', where: 'trip_id = ?', whereArgs: [tripId]);
      final budgetItemsRows = await _dbHelper.query('budget_items', where: 'trip_id = ?', whereArgs: [tripId]);
      final chatMessagesRows = await _dbHelper.query('chat_messages', where: 'trip_id = ?', whereArgs: [tripId]);
      final actualExpensesRows = await _dbHelper.query('actual_expenses', where: 'trip_id = ?', whereArgs: [tripId]);

      // 4. Construct payload (ensuring the user_id matches the active user uid)
      final Map<String, dynamic> tripData = Map<String, dynamic>.from(tripRow);
      tripData['user_id'] = user.uid;

      final Map<String, dynamic> payload = {
        ...tripData,
        'days': daysRows,
        'stops': stopsRows,
        'restaurants': restaurantsRows,
        'budget_items': budgetItemsRows,
        'chat_messages': chatMessagesRows,
        'actual_expenses': actualExpensesRows,
        'synced_at': DateTime.now().toIso8601String(),
      };

      // 5. Upload to Firestore
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .doc(tripId)
          .set(payload, SetOptions(merge: true));

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
  Future<void> restoreTripsFromCloud(String uid) async {
    try {
      final cloudTrips = await fetchTripsFromCloud(uid);
      for (final tripData in cloudTrips) {
        final tripId = tripData['id'] as String;

        // Check if trip already exists locally
        final localTrip = await _dbHelper.queryOne('trips', where: 'id = ?', whereArgs: [tripId]);
        if (localTrip != null) {
          // Skip if already exists
          continue;
        }

        // Write to local SQLite database in a single transaction
        await _dbHelper.executeInTransaction((txn) async {
          // Extract nested tables
          final List<dynamic> days = tripData['days'] as List<dynamic>? ?? [];
          final List<dynamic> stops = tripData['stops'] as List<dynamic>? ?? [];
          final List<dynamic> restaurants = tripData['restaurants'] as List<dynamic>? ?? [];
          final List<dynamic> budgetItems = tripData['budget_items'] as List<dynamic>? ?? [];
          final List<dynamic> chatMessages = tripData['chat_messages'] as List<dynamic>? ?? [];
          final List<dynamic> actualExpenses = tripData['actual_expenses'] as List<dynamic>? ?? [];

          // Remove nested fields to insert the base trip row
          final Map<String, dynamic> tripRow = Map<String, dynamic>.from(tripData)
            ..remove('days')
            ..remove('stops')
            ..remove('restaurants')
            ..remove('budget_items')
            ..remove('chat_messages')
            ..remove('actual_expenses');

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
        });
      }
    } catch (e) {
      debugPrint('CloudSyncService: Error restoring trips from cloud: $e');
    }
  }
}
