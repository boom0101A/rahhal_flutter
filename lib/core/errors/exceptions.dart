class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException: $message (status: $statusCode)';
}

class NetworkException extends AppException {
  NetworkException({String? message}) : super(message: message ?? 'network-exception');
}

class AIException extends AppException {
  AIException({String? message, super.statusCode}) : super(message: message ?? 'ai-exception');
}

class DatabaseException extends AppException {
  DatabaseException({String? message, super.statusCode}) : super(message: message ?? 'database-exception');
}

class AuthException extends AppException {
  AuthException({String? message, super.statusCode}) : super(message: message ?? 'auth-exception');
}

class ParseException extends AppException {
  ParseException({String? message}) : super(message: message ?? 'parse-exception');
}
