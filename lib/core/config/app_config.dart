import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  // Set via: flutter run --dart-define=PROXY_BASE_URL=https://your-server.com
  static const String _envUrl = String.fromEnvironment('PROXY_BASE_URL');

  static String get proxyBaseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;

    if (kIsWeb) {
      // Flutter Web always uses the Railway server (always online, no cold start)
      return 'https://rahhalflutter-production.up.railway.app';
    }

    if (kReleaseMode) {
      return 'https://rahhalflutter-production.up.railway.app';
    }

    // Debug mobile — detect platform without dart:io on web
    // Android emulator: 10.0.2.2 routes to host machine
    // iOS simulator: 127.0.0.1 works
    // Use conditional compilation via Platform (safe because kIsWeb is false here)
    try {
      // This only executes on non-web platforms
      if (_isAndroid()) return 'http://10.0.2.2:3000';
      if (_isIOS()) return 'http://127.0.0.1:3000';
    } catch (_) {}

    return 'http://localhost:3000';
  }

  static bool _isAndroid() {
    // Use defaultTargetPlatform instead of dart:io to avoid issues on Web
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static bool _isIOS() {
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get isProductionMode =>
      proxyBaseUrl.startsWith('https') &&
      !proxyBaseUrl.contains('localhost');

  /// ⚠️ Always false — real AI trips only, no silent fake data.
  static const bool kUseMockFallback = false;

  // Whether server may need warmup (Render free tier)
  static const bool kServerMayNeedWarmup = true;
}
