# ملف كود Dart: lib\core\config\app_config.dart

```dart
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _envUrl = String.fromEnvironment('PROXY_BASE_URL');

  /// Base URL of the backend proxy.
  /// - Use 'http://10.0.2.2:3000' for Android emulator
  /// - Use 'http://localhost:3000' for iOS simulator/Web
  /// - Or compile-time overrides via '--dart-define=PROXY_BASE_URL=https://your-domain.com'
  static String get proxyBaseUrl {
    if (_envUrl.isNotEmpty) {
      return _envUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}

```
