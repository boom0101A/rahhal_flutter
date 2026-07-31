import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Central BlocObserver to log changes and capture unhandled exceptions
/// from all BLoCs and Cubits in the application.
class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('[BLoC ERROR] ${bloc.runtimeType}: $error');
    // Wrapped defensively: this observer is installed before
    // Firebase.initializeApp() runs in main(), and Firebase init itself can
    // fail entirely (main.dart already handles that case for its own error
    // hooks) — either way, FirebaseCrashlytics.instance must not be allowed
    // to throw here and mask the original Bloc error. In debug builds this
    // is a no-op anyway (main.dart disables collection via
    // setCrashlyticsCollectionEnabled(!kDebugMode)), so no separate
    // kDebugMode check is needed here.
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Unhandled error in ${bloc.runtimeType}',
        // The Bloc/Cubit caught this itself — the app kept running, so this
        // is not a "fatal" crash in Crashlytics' sense (unlike main.dart's
        // PlatformDispatcher.onError hook, which only fires for errors
        // nothing else caught).
        fatal: false,
      );
    } catch (_) {}
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      debugPrint('[BLoC] ${bloc.runtimeType}: ${change.nextState.runtimeType}');
    }
  }
}
