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

  // Display — Cairo bold for headings
  static TextStyle get displayLarge => GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.3,
      );

  static TextStyle get displayMedium => GoogleFonts.cairo(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get displaySmall => GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  // Headlines — Cairo semi-bold
  static TextStyle get headlineLarge => GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.4,
      );

  static TextStyle get headlineMedium => GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.4,
      );

  static TextStyle get headlineSmall => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
      );

  // Title
  static TextStyle get titleLarge => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get titleMedium => GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get titleSmall => GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // Body — Cairo regular
  static TextStyle get bodyLarge => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodySmall => GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // Labels — Cairo: these carry UI wording (often Arabic), so they must use
  // an Arabic-capable family rather than Inter.
  static TextStyle get labelLarge => GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get labelMedium => GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // Data / Numbers — Inter for tabular figures, Cairo as Arabic fallback.
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

  static TextStyle get amberLabel => GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.accentAmber,
      );

  // Chip / Badge
  static TextStyle get chip => GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  // Button
  static TextStyle get button => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
}
