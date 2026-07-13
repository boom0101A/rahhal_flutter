# ملف كود Dart: lib\core\errors\exceptions.dart

```dart
import '../constants/app_strings.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException: $message (status: $statusCode)';
}

class NetworkException extends AppException {
  NetworkException({String? message}) : super(message: message ?? AppStrings.exceptionNetwork);
}

class AIException extends AppException {
  AIException({String? message, super.statusCode}) : super(message: message ?? AppStrings.exceptionAI);
}

class DatabaseException extends AppException {
  DatabaseException({String? message, super.statusCode}) : super(message: message ?? AppStrings.exceptionDatabase);
}

class AuthException extends AppException {
  AuthException({String? message, super.statusCode}) : super(message: message ?? AppStrings.exceptionAuth);
}

class ParseException extends AppException {
  ParseException({String? message}) : super(message: message ?? AppStrings.exceptionParse);
}

```
