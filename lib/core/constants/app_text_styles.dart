import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Inter has no Arabic glyphs, so any Inter-styled text containing Arabic
  /// silently falls back to a system font with different metrics — which made
  /// Arabic labels sit off-baseline (descenders clipped) and overflow their
  /// boxes. Numeric/data styles keep Inter for its tabular look but declare
  /// Cairo as an explicit fallback so Arabic characters render correctly.
  static List<String> get _arabicFallback => [GoogleFonts.cairo().fontFamily!];

  /// Set once from the app root (see main.dart) whenever the active locale
  /// changes, including on first launch — every general-UI style below reads
  /// this instead of hardcoding a family, so the switch reaches the whole
  /// app without threading a BuildContext through every call site.
  ///
  /// Arabic keeps Cairo. English switches to Inter: Cairo is an Arabic-first
  /// typeface whose Latin companion glyphs are drawn deliberately lighter
  /// than its Arabic ones — a common trick to balance visual weight against
  /// Arabic's heavier strokes — which reads as thin once English is the only
  /// script on screen. The data/amberBold styles already used Inter for
  /// exactly this reason; this brings the rest of the UI in line with them.
  static bool _isEnglish = false;

  static void setLanguage(String languageCode) {
    _isEnglish = languageCode == 'en';
  }

  static TextStyle _resolve({
    required double fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) {
    if (_isEnglish) {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      ).copyWith(fontFamilyFallback: _arabicFallback);
    }
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  /// Escape hatch for one-off styles outside the named catalog below (e.g. a
  /// ThemeData sub-config that needs a size with no matching named style) —
  /// same Cairo/Inter switch as everything else here, so nothing that uses
  /// it can silently fall out of the design system.
  static TextStyle custom({
    required double fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) =>
      _resolve(fontSize: fontSize, fontWeight: fontWeight, height: height, color: color);

  // Display — bold for headings
  static TextStyle get displayLarge => _resolve(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.3,
      );

  static TextStyle get displayMedium => _resolve(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get displaySmall => _resolve(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  // Headlines — semi-bold
  static TextStyle get headlineLarge => _resolve(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.4,
      );

  static TextStyle get headlineMedium => _resolve(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.4,
      );

  static TextStyle get headlineSmall => _resolve(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
      );

  // Title
  static TextStyle get titleLarge => _resolve(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get titleMedium => _resolve(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get titleSmall => _resolve(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // Body — regular
  static TextStyle get bodyLarge => _resolve(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMedium => _resolve(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodySmall => _resolve(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // Labels — these carry UI wording (often Arabic OR English), so they must
  // track the active language rather than a fixed family.
  static TextStyle get labelLarge => _resolve(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get labelMedium => _resolve(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get labelSmall => _resolve(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // Data / Numbers — always Inter for its tabular figures, regardless of the
  // active language (digits are the same glyphs either way), Cairo as
  // fallback for any Arabic characters mixed alongside them.
  static TextStyle get dataLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ).copyWith(fontFamilyFallback: _arabicFallback);

  static TextStyle get dataMedium => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ).copyWith(fontFamilyFallback: _arabicFallback);

  static TextStyle get dataSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ).copyWith(fontFamilyFallback: _arabicFallback);

  // Amber accented
  static TextStyle get amberBold => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.accentAmber,
      ).copyWith(fontFamilyFallback: _arabicFallback);

  static TextStyle get amberLabel => _resolve(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.accentAmber,
      );

  // Chip / Badge
  static TextStyle get chip => _resolve(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  // Button
  static TextStyle get button => _resolve(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  /// Tab labels. The generous line height keeps Arabic descenders (ل، و، ج)
  /// inside the line box — they were clipped back when Inter-based label
  /// styles (no Arabic glyphs) were used here unconditionally.
  static TextStyle get tabLabel => _resolve(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.6,
      );
}
