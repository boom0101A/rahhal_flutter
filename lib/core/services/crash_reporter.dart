import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Reports a caught-but-otherwise-silent error to Crashlytics as non-fatal,
/// so it's visible in production instead of only via debugPrint (stripped in
/// release builds). Defensively wrapped — mirrors AppBlocObserver.onError —
/// since Crashlytics can itself be unavailable (Firebase init failed, or not
/// ready yet) and must never mask the original error.
void reportNonFatal(Object error, StackTrace stackTrace, {required String reason}) {
  try {
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  } catch (_) {}
}
