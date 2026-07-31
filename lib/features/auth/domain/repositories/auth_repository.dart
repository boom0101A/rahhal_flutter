import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmail(
      String email, String password);
  Future<Either<Failure, UserEntity>> registerWithEmail(
      String email, String password, String displayName);
  Future<Either<Failure, UserEntity>> signInAnonymously();
  Future<Either<Failure, UserEntity>> signInWithGoogle();
  Future<Either<Failure, void>> signOut();

  /// Permanently deletes the signed-in account and its cloud data.
  ///
  /// Required by Google Play's account-deletion policy for any app that lets
  /// users create an account. Fails with `auth/requires-recent-login` when the
  /// session is too old — the caller must re-authenticate and retry.
  Future<Either<Failure, void>> deleteAccount();

  /// Updates the display name shown throughout the app, and returns the
  /// refreshed user. Rejects a blank name — an empty display name would show
  /// as nothing everywhere it's rendered.
  Future<Either<Failure, UserEntity>> updateDisplayName(String name);
  UserEntity? getCurrentUser();
  bool get isAuthenticated;
  Stream<UserEntity?> get authStateChanges;
  Future<String?> getIdToken();

  /// Reconciles local storage with the cloud for [uid] after a sign-in:
  /// claims any locally-stored trip left ownerless by older app versions,
  /// downloads/merges cloud-synced trips, then pushes anything local that
  /// never made it to the cloud (e.g. edits made while offline).
  Future<void> restoreCloudData(String uid);

  /// Wipes every locally-stored row (trips and everything under them). Used
  /// only after [deleteAccount] succeeds — leaving local data behind would
  /// let it resurface via cloud sync on a future sign-in with the same
  /// account, contradicting the deletion the user just asked for.
  Future<void> clearLocalData();
}
