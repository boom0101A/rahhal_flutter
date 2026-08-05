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

  /// Text and icons drawn ON TOP of the amber accent or its gradient.
  ///
  /// Deliberately a fixed navy rather than an `adaptive*` helper: the amber
  /// underneath is the same in both themes, so a foreground that follows the
  /// theme is wrong by construction. Several places used
  /// [adaptiveBgPrimary] here, which in light mode returns the near-white
  /// #F5F7FA and scored 1.94:1 — against a 4.5:1 minimum. This is 8.34:1 on
  /// #F4A235 and 6.84:1 on the gradient's darker #F2871F end.
  static const Color onAmber          = bgPrimary;
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

  /// The "planned" trip status colour.
  ///
  /// The charts' `chart3` blue (#4A90D9) was used here, but it only scores a
  /// 3.3:1 contrast ratio against the light theme's near-white card — under
  /// the 4.5:1 minimum for text — which is why the "مخططة" badge read as a
  /// washed-out grey-blue. These two are picked per theme instead: 5.7:1 on
  /// light, 7.9:1 on dark. Charts keep `chart3` since a chart segment is a
  /// filled area, not small text, and doesn't have the same requirement.
  static Color adaptiveStatusPlanned(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF64B5F6)
          : const Color(0xFF1565C0);

  /// The "active" and "completed" trip status colours.
  ///
  /// StatusBadge draws its label in the same colour as its 18%-alpha fill, so
  /// the label sits on a lightly tinted card, not the raw accent. On the light
  /// card that put "نشطة" at 1.83:1 and "مكتملة" at 2.31:1 — the same defect
  /// [adaptiveStatusPlanned] was introduced to fix, left behind on its two
  /// siblings. These score 4.82:1 and 4.98:1 on light. Dark keeps the amber
  /// (already 4.79:1) but brightens the green, which only managed 3.82:1.
  static Color adaptiveStatusActive(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? accentAmber
          : const Color(0xFF8F5100);

  static Color adaptiveStatusCompleted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF66D9A5)
          : const Color(0xFF146B41);

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
