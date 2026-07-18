import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'core/services/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/favorites/presentation/cubit/favorites_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch unhandled Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 Flutter Error: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  // Catch unexpected asynchronous Dart errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 Platform Error: $error');
    return true; // handled
  };

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Initialize Firebase (wrapped in try-catch for mock/missing config)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // في وضع Debug: AppCheck غير مفعّل تماماً → لا حجب للطلبات
    // في وضع Production: AppCheck مفعّل بالمزودين الرسميين
    if (!kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    }
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('App will continue without Firebase services.');
  }

  // Setup Dependency Injection container
  await setupDependencies();

  // Initialize Local Notification Service
  await NotificationService.initialize();

  runApp(const RahhalApp());
}

class RahhalApp extends StatefulWidget {
  const RahhalApp({super.key});

  static RahhalAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<RahhalAppState>();

  @override
  State<RahhalApp> createState() => RahhalAppState();
}

class RahhalAppState extends State<RahhalApp> {
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
      _themeMode = mode;
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FavoritesCubit>(
          create: (_) => sl<FavoritesCubit>()..loadFavorites(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => sl<AuthCubit>()..checkCurrentUser(),
        ),
      ],
      child: MaterialApp.router(
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
      ),
    );
  }
}
