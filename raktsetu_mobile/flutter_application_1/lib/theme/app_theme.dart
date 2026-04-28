// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Primary — deep medical red (unchanged across light/dark)
  static const primary       = Color(0xFFD0311B);
  static const primaryDark   = Color(0xFFA82412);
  static const primaryLight  = Color(0xFFFF6B55);
  static const primaryFade   = Color(0xFF2D0F0C); // dark-mode fade

  // Status colors — brighter for dark backgrounds
  static const success       = Color(0xFF5DCAA5);
  static const successFade   = Color(0xFF0A2318);
  static const warning       = Color(0xFFEF9F27);
  static const warningFade   = Color(0xFF1F1506);
  static const info          = Color(0xFF378ADD);
  static const infoFade      = Color(0xFF081828);
  static const danger        = Color(0xFFE24B4A);
  static const dangerFade    = Color(0xFF1F0808);

  // Neutrals — dark theme
  static const bg            = Color(0xFF0F0E0C);
  static const surface       = Color(0xFF1A1814);
  static const surfaceHigh   = Color(0xFF242018);
  static const border        = Color(0xFF2C2A26);
  static const borderDark    = Color(0xFF3A3730);
  static const textPrimary   = Color(0xFFF5F3EE);
  static const textSecondary = Color(0xFFA09A8E);
  static const textTertiary  = Color(0xFF706B60);
  static const disabled      = Color(0xFF3A3730);

  // Blood type badge colors — dark mode versions
  static const Map<String, Color> bloodTypeBg = {
    'O_pos': Color(0xFF2D1A10), 'O_neg': Color(0xFF281410),
    'A_pos': Color(0xFF0E1E30), 'A_neg': Color(0xFF0A1828),
    'B_pos': Color(0xFF0A2318), 'B_neg': Color(0xFF081C14),
    'AB_pos': Color(0xFF1A1230), 'AB_neg': Color(0xFF140E28),
  };
  static const Map<String, Color> bloodTypeText = {
    'O_pos': Color(0xFFFF7A66), 'O_neg': Color(0xFFFF6B55),
    'A_pos': Color(0xFF5BA3F5), 'A_neg': Color(0xFF4A94F0),
    'B_pos': Color(0xFF5DCAA5), 'B_neg': Color(0xFF4ABFA0),
    'AB_pos': Color(0xFF9B8FD4), 'AB_neg': Color(0xFF8B7FC8),
  };
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Outfit',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.bg,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // light icons on dark bg
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontFamily: 'Outfit',
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontFamily: 'Outfit',
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 0,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.8),
        headlineLarge: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: -0.3),
        titleLarge: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: -0.3),
        titleMedium: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
        bodyLarge: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: AppColors.textPrimary),
        bodyMedium: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary),
        labelLarge: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: AppColors.textSecondary, letterSpacing: 0.1),
      ),
    );
  }
}