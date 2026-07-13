# ملف كود Dart: lib\core\errors\failures.dart

```dart
import 'package:equatable/equatable.dart';
import '../constants/app_strings.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  NetworkFailure([String? message]) : super(message ?? AppStrings.exceptionNetwork);
}

class AIFailure extends Failure {
  AIFailure([String? message]) : super(message ?? AppStrings.errorAI);
}

class DatabaseFailure extends Failure {
  DatabaseFailure([String? message]) : super(message ?? AppStrings.failureDatabaseLocal);
}

class AuthFailure extends Failure {
  AuthFailure([String? message]) : super(message ?? AppStrings.failureAuthLogin);
}

class CacheFailure extends Failure {
  CacheFailure([String? message]) : super(message ?? AppStrings.failureCache);
}

class ServerFailure extends Failure {
  final int? statusCode;
  ServerFailure({String? message, this.statusCode})
      : super(message ?? AppStrings.failureServer);

  @override
  List<Object?> get props => [message, statusCode];
}

class ValidationFailure extends Failure {
  ValidationFailure([String? message]) : super(message ?? AppStrings.failureValidation);
}

class PermissionFailure extends Failure {
  PermissionFailure([String? message]) : super(message ?? AppStrings.failurePermission);
}

class UnknownFailure extends Failure {
  UnknownFailure([String? message]) : super(message ?? AppStrings.errorGeneral);
}

```
