# ملف كود Dart: lib\core\theme\app_theme.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgPrimary,

        // Color scheme
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentAmber,
          onPrimary: AppColors.bgPrimary,
          secondary: AppColors.accentTurquoise,
          onSecondary: AppColors.bgPrimary,
          surface: AppColors.bgCard,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
          onError: AppColors.textPrimary,
          outline: AppColors.border,
          surfaceContainerHighest: AppColors.bgCard,
        ),

        // Typography
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayMedium,
          displaySmall: AppTextStyles.displaySmall,
          headlineLarge: AppTextStyles.headlineLarge,
          headlineMedium: AppTextStyles.headlineMedium,
          headlineSmall: AppTextStyles.headlineSmall,
          titleLarge: AppTextStyles.titleLarge,
          titleMedium: AppTextStyles.titleMedium,
          titleSmall: AppTextStyles.titleSmall,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.labelLarge,
          labelMedium: AppTextStyles.labelMedium,
          labelSmall: AppTextStyles.labelSmall,
        ),

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bgPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: AppTextStyles.headlineMedium,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),

        // Card
        cardTheme: CardThemeData(
          color: AppColors.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),

        // Input decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputBorder,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.accentAmber, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: AppTextStyles.bodyMedium,
          labelStyle: AppTextStyles.bodyMedium,
        ),

        // Elevated Button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentAmber,
            foregroundColor: AppColors.bgPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            textStyle: AppTextStyles.button,
          ),
        ),

        // Text Button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentAmber,
            textStyle: AppTextStyles.titleMedium,
          ),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.glass,
          selectedColor: AppColors.accentAmber.withValues(alpha: 0.15),
          labelStyle: AppTextStyles.chip,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),

        // Bottom Navigation Bar
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgCard,
          selectedItemColor: AppColors.accentAmber,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.cairo(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.cairo(
            fontSize: 10,
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 0,
        ),

        // Slider
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.accentAmber,
          inactiveTrackColor: AppColors.border,
          thumbColor: AppColors.accentAmber,
          overlayColor: AppColors.accentAmber.withValues(alpha: 0.2),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        ),

        // Page transitions
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),

        // Color scheme
        colorScheme: const ColorScheme.light(
          primary: AppColors.accentAmber,
          onPrimary: Colors.white,
          secondary: AppColors.accentTurquoise,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF0D1B2A),
          error: AppColors.error,
          onError: Colors.white,
          outline: Color(0x1F000000),
          surfaceContainerHighest: Color(0xFFE9ECEF),
        ),

        // Typography overrides for light background readability
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge.copyWith(color: const Color(0xFF0D1B2A)),
          displayMedium: AppTextStyles.displayMedium.copyWith(color: const Color(0xFF0D1B2A)),
          displaySmall: AppTextStyles.displaySmall.copyWith(color: const Color(0xFF0D1B2A)),
          headlineLarge: AppTextStyles.headlineLarge.copyWith(color: const Color(0xFF0D1B2A)),
          headlineMedium: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF0D1B2A)),
          headlineSmall: AppTextStyles.headlineSmall.copyWith(color: const Color(0xFF0D1B2A)),
          titleLarge: AppTextStyles.titleLarge.copyWith(color: const Color(0xFF0D1B2A)),
          titleMedium: AppTextStyles.titleMedium.copyWith(color: const Color(0xFF0D1B2A)),
          titleSmall: AppTextStyles.titleSmall.copyWith(color: const Color(0xFF0D1B2A)),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFF0D1B2A)),
          bodyMedium: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF4B5563)),
          bodySmall: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF4B5563)),
          labelLarge: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF0D1B2A)),
          labelMedium: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF4B5563)),
          labelSmall: AppTextStyles.labelSmall.copyWith(color: const Color(0xFF4B5563)),
        ),

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7FA),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
          ),
          titleTextStyle: TextStyle(color: Color(0xFF0D1B2A), fontSize: 18, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Color(0xFF0D1B2A)),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: Color(0x1F000000),
          thickness: 1,
          space: 0,
        ),
      );
}

```
