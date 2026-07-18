import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  // Set via: flutter run --dart-define=PROXY_BASE_URL=https://your-server.com
  static const String _envUrl = String.fromEnvironment('PROXY_BASE_URL');

  static String get proxyBaseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;

    if (kIsWeb) {
      // Point to local Node.js proxy server
      return 'http://localhost:3000';
    }

    if (kReleaseMode) {
      return 'https://rahhalflutter-production.up.railway.app';
    }

    try {
      if (_isAndroid()) return 'http://10.0.2.2:3000';
      if (_isIOS()) return 'http://127.0.0.1:3000';
    } catch (_) {}

    return 'http://localhost:3000';
  }

  static bool _isAndroid() {
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static bool _isIOS() {
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get isProductionMode =>
      proxyBaseUrl.startsWith('https') &&
      !proxyBaseUrl.contains('localhost');

  /// ✅ Active fallback ensures 100% smooth trip generation experience
  static const bool kUseMockFallback = true;

  // Whether server may need warmup
  static const bool kServerMayNeedWarmup = false;
}
