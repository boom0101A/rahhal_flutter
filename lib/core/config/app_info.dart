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
  static const String buildNumber = '2';

  static String get fullVersion => '$version+$buildNumber';

  /// Where the privacy policy lives. Required by Google Play for any app that
  /// signs users in — replace with the real URL before publishing.
  static const String privacyPolicyUrl =
      'https://rahhal-ai.com/privacy';

  static const String supportEmail = 'support@rahhal-ai.com';
}
