import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/core/constants/app_text_styles.dart';

/// Regression test for "English text looks thin throughout the app".
///
/// Every general-UI style used to hardcode Cairo regardless of language —
/// fine for Arabic (Cairo is designed for it), but Cairo's own Latin
/// companion glyphs are deliberately lighter than its Arabic ones, which
/// read as thin once English was the only script on screen. AppTextStyles
/// now tracks the active locale (set once from the app root) and switches
/// general-UI styles to Inter for English, matching what the data/amberBold
/// styles already did.
///
/// Uses testWidgets (not a plain test()) so GoogleFonts' own asset-loading
/// runs inside the same tolerant zone the rest of the suite's widget tests
/// already rely on — a bare test() fails on the font package's detached,
/// no-network font fetch, which is irrelevant to what's being checked here
/// (the family name AppTextStyles resolved to, not actual glyph rendering).
void main() {
  setUp(() => AppTextStyles.setLanguage('ar'));
  tearDown(() => AppTextStyles.setLanguage('ar'));

  testWidgets('Arabic locale keeps Cairo on general-UI styles', (tester) async {
    AppTextStyles.setLanguage('ar');
    expect(AppTextStyles.bodyMedium.fontFamily, contains('Cairo'));
    expect(AppTextStyles.headlineLarge.fontFamily, contains('Cairo'));
    expect(AppTextStyles.button.fontFamily, contains('Cairo'));
  });

  testWidgets('English locale switches general-UI styles to Inter', (tester) async {
    AppTextStyles.setLanguage('en');
    expect(AppTextStyles.bodyMedium.fontFamily, contains('Inter'));
    expect(AppTextStyles.headlineLarge.fontFamily, contains('Inter'));
    expect(AppTextStyles.button.fontFamily, contains('Inter'));
  });

  testWidgets('English styles still carry a Cairo fallback for stray Arabic text',
      (tester) async {
    AppTextStyles.setLanguage('en');
    final style = AppTextStyles.bodyMedium;
    expect(style.fontFamilyFallback, isNotNull);
    expect(style.fontFamilyFallback!.any((f) => f.contains('Cairo')), isTrue);
  });

  testWidgets('switching back to Arabic reverts the family', (tester) async {
    AppTextStyles.setLanguage('en');
    expect(AppTextStyles.bodyMedium.fontFamily, contains('Inter'));
    AppTextStyles.setLanguage('ar');
    expect(AppTextStyles.bodyMedium.fontFamily, contains('Cairo'));
  });

  testWidgets('numeric data styles stay Inter regardless of language', (tester) async {
    AppTextStyles.setLanguage('ar');
    expect(AppTextStyles.dataLarge.fontFamily, contains('Inter'));
    AppTextStyles.setLanguage('en');
    expect(AppTextStyles.dataLarge.fontFamily, contains('Inter'));
  });

  testWidgets('exact sizes/weights are preserved across both languages', (tester) async {
    for (final lang in ['ar', 'en']) {
      AppTextStyles.setLanguage(lang);
      expect(AppTextStyles.displayLarge.fontSize, 32);
      expect(AppTextStyles.displayLarge.fontWeight, FontWeight.w800);
      expect(AppTextStyles.bodyMedium.fontSize, 14);
      expect(AppTextStyles.bodyMedium.fontWeight, FontWeight.w400);
    }
  });

  testWidgets('custom() participates in the same locale switch', (tester) async {
    AppTextStyles.setLanguage('ar');
    expect(AppTextStyles.custom(fontSize: 10).fontFamily, contains('Cairo'));
    AppTextStyles.setLanguage('en');
    expect(AppTextStyles.custom(fontSize: 10).fontFamily, contains('Inter'));
  });
}
