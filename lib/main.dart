import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'core/di/app_bloc_observer.dart';
import 'core/network/cloud_sync_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_text_styles.dart';
import 'core/router/app_router.dart';
import 'features/favorites/presentation/cubit/favorites_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'shared/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();

  // Crashlytics can only be called once Firebase.initializeApp() below has
  // actually succeeded — if it failed (caught in the try/catch), calling
  // FirebaseCrashlytics.instance here would itself throw and mask the
  // original error, so every report is gated on this flag.
  var firebaseReady = false;

  // Catch unhandled Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 Flutter Error: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
    if (firebaseReady) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // Catch unexpected asynchronous Dart errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 Platform Error: $error');
    if (firebaseReady) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
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
    firebaseReady = true;
    // في وضع Debug: AppCheck وCrashlytics غير مفعّلين تماماً
    // في وضع Production: كلاهما مفعّل
    if (!kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    }
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('App will continue without Firebase services.');
  }

  // Setup Dependency Injection container
  await setupDependencies();

  // Retry any trip whose cloud sync failed (e.g. was offline) the moment
  // connectivity comes back, for the lifetime of the app process.
  sl<CloudSyncService>().startAutoSync();

  // Initialize Local Notification Service
  await NotificationService.initialize();

  // FCM push registration needs a live Firebase app — skip if init failed.
  if (firebaseReady) {
    await sl<FcmService>().initialize();
  }

  // Pre-load locale settings
  final prefs = await SharedPreferences.getInstance();
  final langCode = prefs.getString('language_code') ?? 'ar';
  final countryCode = langCode == 'ar' ? 'AE' : 'US';
  appLocale.value = Locale(langCode, countryCode);

  runApp(const RahhalApp());
}

final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('ar', 'AE'));

class RahhalApp extends StatefulWidget {
  const RahhalApp({super.key});

  static RahhalAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<RahhalAppState>();

  @override
  State<RahhalApp> createState() => RahhalAppState();
}

class RahhalAppState extends State<RahhalApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final themeStr = prefs.getString('theme_mode') ?? 'dark';
    ThemeMode mode = ThemeMode.dark;
    if (themeStr == 'light') {
      mode = ThemeMode.light;
    } else if (themeStr == 'system') {
      mode = ThemeMode.system;
    }

    setState(() {
      _themeMode = mode;
    });
  }

  void setLocale(Locale locale) {
    appLocale.value = locale;
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
      // FavoritesCubit is a singleton loaded once above, and favourites are now
      // filtered per account — so without this, signing into a second account
      // would keep showing the first one's list until the app was restarted.
      // It has to sit inside the MultiBlocProvider to reach both cubits.
      child: BlocListener<AuthCubit, AuthState>(
        // Only on an actual account change: AuthAuthenticated is also re-emitted
        // for things like a display-name edit, and reloading there would make
        // the list flicker for no reason.
        listenWhen: (prev, next) => _signedInUid(prev) != _signedInUid(next),
        listener: (context, _) => context.read<FavoritesCubit>().loadFavorites(),
        child: ValueListenableBuilder<Locale>(
        valueListenable: appLocale,
        builder: (context, currentLocale, _) {
          // Single point of truth for every AppTextStyles getter's font
          // choice (Cairo for Arabic, Inter for English) — runs before
          // AppTheme.lightTheme/darkTheme are built below, and on every
          // locale change (including the very first build), so it never
          // lags behind what's actually on screen.
          AppTextStyles.setLanguage(currentLocale.languageCode);
          return MaterialApp.router(
            title: 'رحّال AI',
            debugShowCheckedModeBanner: false,

            // Theme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeMode,

            // Routing configuration
            routerConfig: AppRouter.router,

            // Wrap screens in OfflineBanner
            builder: (context, child) => OfflineBanner(child: child!),

            // Localization & RTL support
            locale: currentLocale,
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
        },
        ),
      ),
    );
  }
}

/// The uid of the signed-in account, or null when nobody is signed in.
String? _signedInUid(AuthState state) =>
    state is AuthAuthenticated ? state.user.uid : null;
