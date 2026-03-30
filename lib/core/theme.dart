import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Mana Hospital — Design System
/// ─────────────────────────────────────────────────────────────────────────────
/// Palette: Pure White → Light Blue → Medical Sky Blue (no Red/Green/Yellow)
/// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Core palette
  static const Color white         = Color(0xFFFFFFFF);
  static const Color paleSkyBlue   = Color(0xFFE1F5FE); // ~LightBlue[50]
  static const Color lightBlue100  = Color(0xFFB3E5FC); // LightBlue[100]
  static const Color skyBlue300    = Color(0xFF4FC3F7); // LightBlue[300]
  static const Color skyBlue500    = Color(0xFF03A9F4); // LightBlue[500]
  static const Color medicalBlue   = Color(0xFF0288D1); // LightBlue[700]
  static const Color deepBlue      = Color(0xFF0277BD); // LightBlue[800]
  static const Color darkBlue      = Color(0xFF01579B); // LightBlue[900]

  // Text
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textOnBlue    = Color(0xFFFFFFFF);
  static const Color textHint      = Color(0xFF90A4AE);

  // Background
  static const Color background    = Color(0xFFF8FBFF);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color cardBorder    = Color(0xFFE1F5FE);

  // Slot gradient stops — mapped by occupancy level (0-5)
  static List<Color> slotGradient(int booked) {
    if (booked <= 1) {
      return [white, white];
    } else if (booked <= 2) {
      return [white, paleSkyBlue];
    } else if (booked <= 3) {
      return [white, lightBlue100];
    } else if (booked == 4) {
      return [lightBlue100, skyBlue300];
    } else {
      // 5/5 — Full
      return [medicalBlue, deepBlue];
    }
  }
}

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Outfit';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppTextStyles.fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.medicalBlue,
          brightness: Brightness.light,
          surface: AppColors.background,
          primary: AppColors.medicalBlue,
          onPrimary: AppColors.white,
          secondary: AppColors.skyBlue300,
          onSecondary: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyles.titleLarge,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.medicalBlue,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.medicalBlue,
            side: const BorderSide(color: AppColors.medicalBlue, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.paleSkyBlue.withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.medicalBlue, width: 2),
          ),
          hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.cardBorder,
          thickness: 1,
        ),
      );
}
