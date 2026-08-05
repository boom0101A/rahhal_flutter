import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/cloud_sync_service.dart';
import '../../trip_documents/data/document_file_service.dart';
import '../domain/entities/user_entity.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper _dbHelper;
  final CloudSyncService _syncService;

  AuthRepositoryImpl({
    required DatabaseHelper dbHelper,
    required CloudSyncService syncService,
  })  : _dbHelper = dbHelper,
        _syncService = syncService;

  @override
  bool get isAuthenticated {
    try {
      return firebase_auth.FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  UserEntity? getCurrentUser() {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;
      return UserEntity(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        isAnonymous: firebaseUser.isAnonymous,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    try {
      return firebase_auth.FirebaseAuth.instance.authStateChanges().map((firebaseUser) {
        if (firebaseUser == null) return null;
        return UserEntity(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          isAnonymous: firebaseUser.isAnonymous,
        );
      });
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail(
      String email, String password) async {
    try {
      final credential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Left(AuthFailure('auth/failed-retrieve-user-data'));
      }
      final userEntity = UserEntity(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        isAnonymous: firebaseUser.isAnonymous,
      );
      return Right(userEntity);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure('auth/${e.code}'));
    } catch (e) {
      return Left(AuthFailure('auth/unexpected-error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail(
      String email, String password, String displayName) async {
    try {
      final credential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Left(AuthFailure('auth/failed-create-account'));
      }

      // Update Firebase Auth profile display name
      await firebaseUser.updateDisplayName(displayName);
      await firebaseUser.reload();

      final updatedUser =
          firebase_auth.FirebaseAuth.instance.currentUser ?? firebaseUser;

      // حفظ Firestore بشكل منفصل — لا يُفشل التسجيل إذا فشل Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(updatedUser.uid)
            .set({
          'uid': updatedUser.uid,
          'email': updatedUser.email,
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        // المستخدم تم إنشاؤه بنجاح في Firebase Auth — Firestore غير حرج
        debugPrint('Firestore save failed (non-critical): $firestoreError');
      }

      final userEntity = UserEntity(
        uid: updatedUser.uid,
        email: updatedUser.email,
        displayName: displayName,
        photoUrl: updatedUser.photoURL,
        isAnonymous: updatedUser.isAnonymous,
      );
      return Right(userEntity);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure('auth/${e.code}'));
    } catch (e) {
      return Left(AuthFailure('auth/unexpected-error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInAnonymously() async {
    try {
      final credential =
          await firebase_auth.FirebaseAuth.instance.signInAnonymously();
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Left(AuthFailure('auth/guest-sign-in-failed'));
      }
      final userEntity = UserEntity(
        uid: firebaseUser.uid,
        displayName: 'Guest',
        isAnonymous: true,
      );
      return Right(userEntity);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure('auth/${e.code}'));
    } catch (e) {
      return Left(AuthFailure('auth/unexpected-error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '226504199183-fr97u1d1v5df6kt6n2666c432rfe0pcg.apps.googleusercontent.com'
            : null,
        scopes: ['email', 'profile'],
      );

      // Sign out first to force account picker for better UX
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[GoogleSignIn] User cancelled sign-in');
        return const Left(AuthFailure('auth/google-sign-in-canceled'));
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final authResult = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
      final firebaseUser = authResult.user;
      if (firebaseUser == null) {
        return const Left(AuthFailure('auth/failed-retrieve-user-data'));
      }

      // حفظ Firestore بشكل منفصل — لا يُفشل تسجيل الدخول إذا فشل Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName ?? '',
          'photoUrl': firebaseUser.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (firestoreError) {
        // تسجيل الدخول نجح في Firebase Auth — Firestore غير حرج
        debugPrint('Firestore save failed (non-critical): $firestoreError');
      }

      final userEntity = UserEntity(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        isAnonymous: firebaseUser.isAnonymous,
      );
      return Right(userEntity);
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('[GoogleSignIn] Firebase error: ${e.code} — ${e.message}');
      return Left(AuthFailure('auth/${e.code}'));
    } catch (e) {
      debugPrint('[GoogleSignIn] Unexpected error: $e');
      return Left(AuthFailure('auth/google-sign-in-failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure('auth/sign-out-failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Left(AuthFailure('auth/empty-display-name'));
    }
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return Left(AuthFailure('auth/no-current-user'));

    try {
      await user.updateDisplayName(trimmed);
      // updateDisplayName mutates the SDK's cached user object directly, but
      // reload() is what makes that change visible to a FRESH read of
      // currentUser — without it, a caller reading currentUser again later
      // one gets a stale value.
      await user.reload();
      final refreshed = firebase_auth.FirebaseAuth.instance.currentUser!;
      return Right(UserEntity(
        uid: refreshed.uid,
        email: refreshed.email,
        displayName: refreshed.displayName,
        photoUrl: refreshed.photoURL,
        isAnonymous: refreshed.isAnonymous,
      ));
    } catch (e) {
      return Left(AuthFailure('auth/update-name-failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return Left(AuthFailure('auth/no-current-user'));

    // Remove the cloud copy FIRST: once the auth account is gone the security
    // rules no longer match this uid, which would strand the document
    // undeletable.
    try {
      // Firestore never cascade-deletes subcollections when their parent
      // document is deleted — deleting only users/{uid} would leave every
      // trip the account ever synced (users/{uid}/trips/*) in the database
      // forever, unreachable by anyone once the account itself is gone.
      await _deleteAllUserTrips(user.uid);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
    } catch (e) {
      debugPrint('[Auth] cloud data delete failed (continuing): $e');
    }

    // Wipe local data unconditionally too, BEFORE attempting user.delete()
    // below — not after it succeeds. user.delete() commonly fails with
    // requires-recent-login (Firebase requires a fresh sign-in to remove the
    // Auth record, and most sessions aren't that fresh), which used to leave
    // the cloud copy gone but every local trip fully intact and the account
    // still signed in — so "delete account" silently did nothing from the
    // user's point of view: same data, still logged in, reachable again on
    // the next sign-in. The user's data must not survive their explicit
    // deletion request just because this last, separate step failed.
    await clearLocalData();

    try {
      // Also drop the Google session so the next sign-in shows the account
      // picker instead of silently reusing the deleted one.
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      await user.delete();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Data is already gone at this point either way — this failure only
      // means the Firebase Auth record itself is still there. Surfaced
      // verbatim so the UI can tell the user to sign in again and retry to
      // remove that too, rather than showing a generic error.
      return Left(AuthFailure('auth/${e.code}'));
    } catch (e) {
      return Left(AuthFailure('auth/delete-failed: ${e.toString()}'));
    }
  }

  /// Deletes every document in `users/{uid}/trips` — the one subcollection
  /// the app actually writes to (see cloud_sync_service.dart). The client
  /// SDK has no way to discover subcollection names it doesn't already know
  /// about, so if a future feature adds another subcollection under a user,
  /// this needs a matching addition or that data will be orphaned the same
  /// way `trips` used to be.
  ///
  /// Batches at 400 (under Firestore's 500-per-batch limit) and repeats
  /// until nothing is left, so this works regardless of how many trips the
  /// account has.
  Future<void> _deleteAllUserTrips(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final tripsRef =
        firestore.collection('users').doc(uid).collection('trips');
    while (true) {
      final snapshot = await tripsRef.limit(400).get();
      if (snapshot.docs.isEmpty) break;
      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < 400) break;
    }
  }

  @override
  Future<String?> getIdToken() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> restoreCloudData(String uid) async {
    // Claim any locally-stored trip that predates per-account filtering
    // (was left with no owner) before this account can see its trip list —
    // otherwise a second account signing in on this device would still see
    // the first account's trips. Awaited (it's one local UPDATE) so the
    // claim always finishes before the trip list can be shown; a no-op once
    // no unclaimed trips remain.
    try {
      await _dbHelper.claimOrphanedTrips(uid);
      // Same reasoning, same timing: favourites are scoped per account too,
      // so unowned ones have to be claimed here or they'd be invisible to
      // every account and look like they were deleted by the update.
      await _dbHelper.claimOrphanedFavorites(uid);
    } catch (e) {
      debugPrint('AuthRepository: Failed to claim orphaned trips: $e');
    }
    try {
      await _syncService.restoreTripsFromCloud(uid);
    } catch (e) {
      debugPrint('AuthRepository: Failed to restore cloud data: $e');
    }
    // Push anything created/edited locally (e.g. while offline) that never
    // made it to the cloud — catches failures the fire-and-forget sync calls
    // elsewhere couldn't retry themselves.
    try {
      await _syncService.syncPendingTrips();
    } catch (e) {
      debugPrint('AuthRepository: Failed to sync pending trips: $e');
    }
  }

  @override
  Future<void> clearLocalData() async {
    try {
      await _dbHelper.clearAllData();
    } catch (e) {
      debugPrint('[Auth] local data wipe failed: $e');
    }
    // Document photos are files, not rows, so clearAllData doesn't reach them.
    // Done here rather than inside DatabaseHelper, which has no business
    // touching path_provider.
    try {
      await DocumentFileService.deleteAll();
    } catch (e) {
      debugPrint('[Auth] document image wipe failed: $e');
    }
  }
}
