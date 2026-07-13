import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _envUrl = String.fromEnvironment('PROXY_BASE_URL');
  static const String _productionCloudUrl = 'https://rahhal-ai-proxy.onrender.com';

  /// Base URL of the backend proxy.
  /// Defaults to live cloud proxy server on Render.
  static String get proxyBaseUrl {
    if (_envUrl.isNotEmpty) {
      return _envUrl;
    }
    return _productionCloudUrl;
  }
}
