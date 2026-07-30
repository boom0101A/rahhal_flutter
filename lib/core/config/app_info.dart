/// Single source of truth for the app's identity strings.
///
/// The version was previously hardcoded inside the About dialog, so it silently
/// went stale every release. Keeping it here means one edit per release instead
/// of hunting through UI code.
class AppInfo {
  AppInfo._();

  /// Must match `version:` in pubspec.yaml (the part before the `+`).
  static const String version = '1.0.0';

  /// The build number from pubspec.yaml (after the `+`). Shorebird patches ride
  /// on top of a release with this build number, so it identifies which native
  /// binary is installed.
  static const String buildNumber = '5';

  static String get fullVersion => '$version+$buildNumber';

  /// Where the privacy policy lives. Required by Google Play for any app that
  /// signs users in. Hosted on Firebase Hosting (project: rahhal-ai) — see
  /// public/privacy.html; deploy updates with `firebase deploy --only hosting`.
  static const String privacyPolicyUrl =
      'https://rahhal-ai.web.app/privacy.html';

  /// Same hosting setup as [privacyPolicyUrl] — see public/terms.html.
  static const String termsOfServiceUrl =
      'https://rahhal-ai.web.app/terms.html';

  static const String supportEmail = 'ah0450278@gmail.com';
}
