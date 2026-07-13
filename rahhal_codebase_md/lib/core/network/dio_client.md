# ملف كود Dart: lib\core\network\dio_client.dart

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../di/injection.dart';
import '../errors/exceptions.dart';
import '../constants/app_strings.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class DioClient {
  static Dio? _anthropicInstance;
  static Dio? _generalInstance;

  /// Dio instance pre-configured for the Anthropic Claude API.
  static Dio get anthropic {
    _anthropicInstance ??= _buildAnthropicDio();
    return _anthropicInstance!;
  }

  /// General-purpose Dio instance (e.g. for image APIs).
  static Dio get general {
    _generalInstance ??= _buildGeneralDio();
    return _generalInstance!;
  }

  static Dio _buildAnthropicDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.proxyBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: false, // Don't log full body (contains prompts)
        responseBody: false,
        logPrint: (o) => debugPrint('[DIO] $o'),
      ));
    }

    dio.interceptors.add(_FirebaseTokenInterceptor());
    dio.interceptors.add(_RetryInterceptor(dio, maxRetries: 2));
    dio.interceptors.add(_ErrorInterceptor());

    return dio;
  }

  static Dio _buildGeneralDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(logPrint: (o) => debugPrint('[DIO] $o')));
    }
    dio.interceptors.add(_ErrorInterceptor());
    return dio;
  }
}

/// Interceptor that attaches the Firebase Auth ID token to headers.
class _FirebaseTokenInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final authRepo = sl<AuthRepository>();
      final token = await authRepo.getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint('[_FirebaseTokenInterceptor] Failed to get ID token: $e');
    }
    super.onRequest(options, handler);
  }
}

/// Retries failed requests on connection errors (not on 4xx).
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;

  _RetryInterceptor(this._dio, {this.maxRetries = 2});

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = (extra['retryCount'] as int?) ?? 0;

    final shouldRetry = retryCount < maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError);

    if (shouldRetry) {
      await Future.delayed(Duration(seconds: retryCount + 1));
      try {
        final options = err.requestOptions;
        options.extra['retryCount'] = retryCount + 1;
        final response = await _dio.request<dynamic>(
          options.path,
          data: options.data,
          queryParameters: options.queryParameters,
          options: Options(
            method: options.method,
            headers: options.headers,
            extra: options.extra,
          ),
        );
        handler.resolve(response);
        return;
      } catch (_) {
        // fall through to original error
      }
    }
    handler.next(err);
  }
}

/// Converts Dio errors into typed [AppException]s.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      throw NetworkException();
    }
    if (err.response != null) {
      final statusCode = err.response!.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) {
        throw AIException(
          message: AppStrings.errorInvalidApiKey,
          statusCode: statusCode,
        );
      }
      if (statusCode == 429) {
        throw AIException(
          message: AppStrings.errorRateLimit,
          statusCode: statusCode,
        );
      }
      throw AIException(
        message: AppStrings.errorServerFormat.replaceAll('%s', statusCode.toString()),
        statusCode: statusCode,
      );
    }
    handler.next(err);
  }
}

```
