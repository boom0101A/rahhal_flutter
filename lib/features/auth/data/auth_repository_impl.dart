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
