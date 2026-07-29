# Baseline keep rules for R8 code shrinking/obfuscation on the release build.
# Most Firebase/Google/Flutter plugins already ship their own consumer
# ProGuard rules bundled in their AAR, so this file only covers the common
# gaps: Flutter's own runtime, Firebase/Play Services reflection surfaces,
# and metadata R8 strips by default that some plugins rely on at runtime.

# Flutter engine and generated plugin registrant
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase / Google Play Services (Auth, Firestore, App Check, Sign-In)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Metadata some plugins rely on via reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable

# Optional Play Core split-install classes referenced by some plugins but
# not actually used by this app (no dynamic feature modules) — safe to
# silence rather than keep, since they're never invoked at runtime.
-dontwarn com.google.android.play.core.**
