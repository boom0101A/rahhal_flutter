import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// Read from --dart-define at build time, fallback to localhost for emulator / cloud URL
  static const String proxyBaseUrl = String.fromEnvironment(
    'PROXY_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator → host machine
  );

  /// Returns true if proxy URL is pointing to a live cloud host (e.g. Render / domain)
  static bool get isProductionMode =>
      !proxyBaseUrl.contains('localhost') &&
      !proxyBaseUrl.contains('10.0.2.2') &&
      !proxyBaseUrl.contains('127.0.0.1') &&
      !proxyBaseUrl.contains('192.168');

  /// ⚠️ NEVER set this to true in production.
  /// When true (debug/QA only), API failures silently fall back to mock data.
  /// In production this must always be false so real errors surface to the user.
  static const bool kUseMockFallback = kDebugMode && false;

  /// Hint: Render free-tier server needs ~30-50s to wake up after inactivity.
  /// The UI will show a "may take up to a minute on first use" message.
  static const bool kServerMayNeedWarmup = true;
}
