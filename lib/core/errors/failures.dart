import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'network-failure']);
}

class AIFailure extends Failure {
  const AIFailure([super.message = 'ai-failure']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'database-failure']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'auth-failure']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'cache-error']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([super.message = 'server-failure', this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'validation-failure']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'permission-failure']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'unknown-failure']);
}
