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
  UserEntity? getCurrentUser();
  bool get isAuthenticated;
  Stream<UserEntity?> get authStateChanges;
  Future<String?> getIdToken();
}
