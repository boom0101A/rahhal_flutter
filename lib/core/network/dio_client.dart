import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../di/injection.dart';
import '../errors/exceptions.dart';

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
        connectTimeout: const Duration(seconds: 90), // 90s to allow Render free-tier cold start (50-120s)
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
    dio.interceptors.add(_RetryInterceptor(dio, maxRetries: 3));
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
    // إذا كان الخطأ 401 (Unauthorized)، جرّب تجديد التوكن تلقائياً
    if (err.response?.statusCode == 401) {
      try {
        final user = firebase_auth.FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Force refresh the token
          final newToken = await user.getIdToken(true); // forceRefresh = true
          
          // Retry the request with new token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        }
      } catch (refreshError) {
        debugPrint('[Auth] Token refresh failed: $refreshError');
      }
    }

    final extra = err.requestOptions.extra;
    final retryCount = (extra['retryCount'] as int?) ?? 0;

    final shouldRetry = retryCount < maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError);

    if (shouldRetry) {
      // Exponential backoff: 2s, 4s, 8s — gives server more time to boot
      await Future.delayed(Duration(seconds: 2 << retryCount));
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
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: NetworkException(),
        type: err.type,
      ));
      return;
    }
    if (err.response != null) {
      final statusCode = err.response!.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) {
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: AIException(message: 'invalid-api-key', statusCode: statusCode),
        ));
        return;
      }
      if (statusCode == 429) {
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: AIException(message: 'rate-limit', statusCode: statusCode),
        ));
        return;
      }
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: AIException(
          message: 'server-error-$statusCode',
          statusCode: statusCode,
        ),
      ));
      return;
    }
    handler.next(err);
  }
}
