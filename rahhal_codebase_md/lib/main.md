# ملف كود Dart: lib\main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Setup Dependency Injection container
  await setupDependencies();

  runApp(const RahhalApp());
}

class RahhalApp extends StatefulWidget {
  const RahhalApp({super.key});

  static _RahhalAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_RahhalAppState>();

  @override
  State<RahhalApp> createState() => _RahhalAppState();
}

class _RahhalAppState extends State<RahhalApp> {
  Locale _locale = const Locale('ar', 'AE');
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load locale
    final langCode = prefs.getString('language_code') ?? 'ar';
    final countryCode = langCode == 'ar' ? 'AE' : 'US';
    
    // Load theme
    final themeStr = prefs.getString('theme_mode') ?? 'dark';
    ThemeMode mode = ThemeMode.dark;
    if (themeStr == 'light') {
      mode = ThemeMode.light;
    } else if (themeStr == 'system') {
      mode = ThemeMode.system;
    }

    setState(() {
      _locale = Locale(langCode, countryCode);
      AppStrings.setLanguage(langCode);
      _themeMode = mode;
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
      AppStrings.setLanguage(locale.languageCode);
    });
  }

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'رحّال AI',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,

      // Routing configuration
      routerConfig: AppRouter.router,

      // Localization & RTL support
      locale: _locale,
      supportedLocales: const [
        Locale('ar', 'AE'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

```
