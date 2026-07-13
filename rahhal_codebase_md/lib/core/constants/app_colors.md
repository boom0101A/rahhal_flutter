# ملف كود Dart: lib\core\constants\app_colors.dart

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bgPrimary = Color(0xFF0D1B2A);
  static const Color bgCard = Color(0xFF1A2E42);
  static const Color bgPopover = Color(0xFF15263A);

  // Accents
  static const Color accentAmber = Color(0xFFF4A235);
  static const Color accentAmberDark = Color(0xFFF2871F);
  static const Color accentTurquoise = Color(0xFF2EC4B6);

  // Text
  static const Color textPrimary = Color(0xFFF0EBE3);
  static const Color textSecondary = Color(0xFF8FA3B1);

  // Status
  static const Color success = Color(0xFF4CAF82);
  static const Color error = Color(0xFFE05C5C);

  // Glass
  static const Color glass = Color(0x0FFFFFFF); // ~6% white
  static const Color glassBorder = Color(0x14FFFFFF); // ~8% white
  static const Color glassStrong = Color(0xB31A2E42); // 70% bgCard

  // Borders
  static const Color border = Color(0x14FFFFFF);
  static const Color inputBorder = Color(0x1AFFFFFF);

  // Charts
  static const Color chart1 = accentAmber;
  static const Color chart2 = accentTurquoise;
  static const Color chart3 = Color(0xFF4A90D9);
  static const Color chart4 = success;
  static const Color chart5 = textSecondary;

  // Gradients
  static const LinearGradient amberGradient = LinearGradient(
    colors: [accentAmber, accentAmberDark],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [bgPrimary, Color(0x661A2E42), Color(0x1A0D1B2A)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0x4DF4A235), Color(0x332EC4B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glows (as shadows)
  static List<BoxShadow> get amberGlow => [
        BoxShadow(
          color: accentAmber.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get amberGlowStrong => [
        BoxShadow(
          color: accentAmber.withValues(alpha: 0.4),
          blurRadius: 28,
        ),
      ];

  static List<BoxShadow> get turquoiseGlow => [
        BoxShadow(
          color: accentTurquoise.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

```
