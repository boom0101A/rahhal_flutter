# ملف كود Dart: lib\features\auth\data\auth_repository_impl.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/errors/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../domain/entities/user_entity.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  bool get isAuthenticated =>
      firebase_auth.FirebaseAuth.instance.currentUser != null;

  @override
  UserEntity? getCurrentUser() {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    return UserEntity(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isAnonymous: firebaseUser.isAnonymous,
    );
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
        return Left(AuthFailure(AppStrings.languageCode == 'ar'
            ? 'تعذر الحصول على بيانات المستخدم بعد تسجيل الدخول.'
            : 'Failed to retrieve user data after login.'));
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
      final isAr = AppStrings.languageCode == 'ar';
      String message = isAr ? 'حدث خطأ أثناء تسجيل الدخول' : 'An error occurred during login';
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          message = isAr
              ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
              : 'Incorrect email or password.';
          break;
        case 'wrong-password':
          message = isAr ? 'كلمة المرور غير صحيحة.' : 'Incorrect password.';
          break;
        case 'invalid-email':
          message = isAr ? 'البريد الإلكتروني غير صالح.' : 'Invalid email address.';
          break;
        case 'user-disabled':
          message = isAr ? 'تم تعطيل هذا الحساب.' : 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = isAr
              ? 'محاولات كثيرة خاطئة. يرجى المحاولة لاحقاً.'
              : 'Too many failed attempts. Please try again later.';
          break;
        default:
          if (e.message != null) {
            message = e.message!;
          }
      }
      return Left(AuthFailure(message));
    } catch (e) {
      return Left(AuthFailure(AppStrings.languageCode == 'ar'
          ? 'خطأ غير متوقع: ${e.toString()}'
          : 'Unexpected error: ${e.toString()}'));
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
        return Left(AuthFailure(AppStrings.languageCode == 'ar'
            ? 'تعذر إنشاء حساب مستخدم.'
            : 'Failed to create user account.'));
      }

      // Update Firebase Auth profile display name
      await firebaseUser.updateDisplayName(displayName);
      await firebaseUser.reload();

      final updatedUser =
          firebase_auth.FirebaseAuth.instance.currentUser ?? firebaseUser;

      // Save user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(updatedUser.uid).set({
        'uid': updatedUser.uid,
        'email': updatedUser.email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final userEntity = UserEntity(
        uid: updatedUser.uid,
        email: updatedUser.email,
        displayName: displayName,
        photoUrl: updatedUser.photoURL,
        isAnonymous: updatedUser.isAnonymous,
      );
      return Right(userEntity);
    } on firebase_auth.FirebaseAuthException catch (e) {
      final isAr = AppStrings.languageCode == 'ar';
      String message = isAr ? 'حدث خطأ أثناء إنشاء الحساب' : 'An error occurred during registration';
      switch (e.code) {
        case 'email-already-in-use':
          message = isAr ? 'البريد الإلكتروني مستخدم بالفعل.' : 'Email is already in use.';
          break;
        case 'weak-password':
          message = isAr
              ? 'كلمة المرور ضعيفة جداً. يجب أن تكون 6 أحرف على الأقل.'
              : 'Password is too weak. Must be at least 6 characters.';
          break;
        case 'invalid-email':
          message = isAr ? 'البريد الإلكتروني غير صالح.' : 'Invalid email address.';
          break;
        default:
          if (e.message != null) {
            message = e.message!;
          }
      }
      return Left(AuthFailure(message));
    } catch (e) {
      return Left(AuthFailure(AppStrings.languageCode == 'ar'
          ? 'خطأ غير متوقع: ${e.toString()}'
          : 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInAnonymously() async {
    try {
      final credential =
          await firebase_auth.FirebaseAuth.instance.signInAnonymously();
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return Left(AuthFailure(AppStrings.languageCode == 'ar'
            ? 'تعذر تسجيل الدخول كزائر.'
            : 'Failed to sign in as guest.'));
      }
      final userEntity = UserEntity(
        uid: firebaseUser.uid,
        displayName: AppStrings.authGuestMode,
        isAnonymous: true,
      );
      return Right(userEntity);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? (AppStrings.languageCode == 'ar'
          ? 'حدث خطأ أثناء تسجيل الدخول كزائر.'
          : 'An error occurred while signing in as guest.')));
    } catch (e) {
      return Left(AuthFailure(AppStrings.languageCode == 'ar'
          ? 'خطأ غير متوقع: ${e.toString()}'
          : 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(AppStrings.languageCode == 'ar'
          ? 'حدث خطأ أثناء تسجيل الخروج: ${e.toString()}'
          : 'An error occurred while logging out: ${e.toString()}'));
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

```
