import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/failures.dart';
import '../domain/entities/user_entity.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
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

    try {
      // Remove the cloud copy FIRST: once the auth account is gone the security
      // rules no longer match this uid, which would strand the document
      // undeletable.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
      } catch (e) {
        debugPrint('[Auth] cloud data delete failed (continuing): $e');
      }

      // Also drop the Google session so the next sign-in shows the account
      // picker instead of silently reusing the deleted one.
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      await user.delete();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Firebase refuses deletion on a stale session — surfaced verbatim so the
      // UI can tell the user to sign in again rather than showing a generic error.
      return Left(AuthFailure('auth/${e.code}'));
    } catch (e) {
      return Left(AuthFailure('auth/delete-failed: ${e.toString()}'));
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
}
