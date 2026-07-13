import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ═══ Dark Mode Colors ═══
  static const Color bgPrimary     = Color(0xFF0D1B2A);
  static const Color bgCard        = Color(0xFF1A2E42);
  static const Color bgPopover     = Color(0xFF15263A);
  static const Color textPrimary   = Color(0xFFF0EBE3);
  static const Color textSecondary = Color(0xFF8FA3B1);
  static const Color glass         = Color(0x0FFFFFFF);
  static const Color glassBorder   = Color(0x14FFFFFF);
  static const Color glassStrong   = Color(0xB31A2E42);
  static const Color border        = Color(0x14FFFFFF);
  static const Color inputBorder   = Color(0x1AFFFFFF);

  // ═══ Light Mode Colors ═══
  static const Color bgPrimaryLight     = Color(0xFFF5F7FA);
  static const Color bgCardLight        = Color(0xFFFFFFFF);
  static const Color bgPopoverLight     = Color(0xFFF0F2F5);
  static const Color textPrimaryLight   = Color(0xFF0D1B2A);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color glassLight         = Color(0x0F000000);
  static const Color glassBorderLight   = Color(0x18000000);
  static const Color glassStrongLight   = Color(0xE6FFFFFF);
  static const Color borderLight        = Color(0x18000000);
  static const Color inputBorderLight   = Color(0x1A000000);

  // ═══ Shared / Accent Colors ═══
  static const Color accentAmber      = Color(0xFFF4A235);
  static const Color accentAmberDark  = Color(0xFFF2871F);
  static const Color accentTurquoise  = Color(0xFF2EC4B6);
  static const Color success          = Color(0xFF4CAF82);
  static const Color error            = Color(0xFFE05C5C);

  // ═══ Adaptive Helpers ═══
  static Color adaptiveBgPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? bgPrimary
          : bgPrimaryLight;

  static Color adaptiveBgCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? bgCard
          : bgCardLight;

  static Color adaptiveBgPopover(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? bgPopover
          : bgPopoverLight;

  static Color adaptiveTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimary
          : textPrimaryLight;

  static Color adaptiveTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondary
          : textSecondaryLight;

  static Color adaptiveGlass(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? glass
          : glassLight;

  static Color adaptiveGlassBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? glassBorder
          : glassBorderLight;

  static Color adaptiveGlassStrong(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? glassStrong
          : glassStrongLight;

  static Color adaptiveBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? border
          : borderLight;

  static Color adaptiveInputBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? inputBorder
          : inputBorderLight;

  // ═══ Charts ═══
  static const Color chart1 = accentAmber;
  static const Color chart2 = accentTurquoise;
  static const Color chart3 = Color(0xFF4A90D9);
  static const Color chart4 = success;
  static const Color chart5 = textSecondary;

  // ═══ Gradients ═══
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

  static LinearGradient adaptiveHeroGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [bgPrimary, const Color(0x661A2E42), const Color(0x1A0D1B2A)]
          : [bgPrimaryLight, const Color(0x66FFFFFF), const Color(0x1AF5F7FA)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
  }

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0x4DF4A235), Color(0x332EC4B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══ Glows (as shadows) ═══
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
