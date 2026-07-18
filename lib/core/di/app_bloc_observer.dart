import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Central BlocObserver to log changes and capture unhandled exceptions
/// from all BLoCs and Cubits in the application.
class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('[BLoC ERROR] ${bloc.runtimeType}: $error');
    // In production: send to Firebase Crashlytics if initialized
    // try {
    //   FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // } catch (_) {}
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      debugPrint('[BLoC] ${bloc.runtimeType}: ${change.nextState.runtimeType}');
    }
  }
}
