import 'package:flutter/material.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';

class AppTheme {
  static ThemeData lightTheme() {
    const scheme = ColorScheme.light(
      primary: AppColors.emerald,
      secondary: AppColors.emerald,
      surface: AppColors.lightSurface,
      error: AppColors.expense,
      onPrimary: Colors.white,
      onSurface: AppColors.lightTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: _textTheme(Brightness.light),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface.withValues(alpha: 0.74),
        elevation: AppElevation.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.78)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      dividerColor: AppColors.lightSurfaceAlt,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceAlt,
        labelStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: AppColors.lightSurfaceAlt.withValues(alpha: 0.9),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.emerald, width: 1.25),
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.emerald,
          fontWeight: FontWeight.w700,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          backgroundColor: const WidgetStatePropertyAll(AppColors.lightSurface),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: AppColors.lightSurfaceAlt.withValues(alpha: 0.85),
            ),
          ),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        side: BorderSide.none,
        selectedColor: AppColors.emerald.withValues(alpha: 0.18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(
            color: AppColors.lightSurfaceAlt.withValues(alpha: 0.85),
          ),
          backgroundColor: AppColors.lightSurface,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: AppColors.lightSurfaceAlt.withValues(alpha: 0.85),
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        elevation: AppElevation.fab,
      ),
    );
  }

  static ThemeData darkTheme() {
    const scheme = ColorScheme.dark(
      primary: AppColors.emerald,
      secondary: AppColors.emerald,
      surface: AppColors.darkSurface,
      error: AppColors.expense,
      onPrimary: Colors.white,
      onSurface: AppColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _textTheme(Brightness.dark),
      cardTheme: CardThemeData(
        color: const Color(0xFF4E5A56).withValues(alpha: 0.52),
        elevation: AppElevation.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      dividerColor: AppColors.darkSurfaceAlt,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceAlt,
        labelStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: AppColors.darkTextSecondary.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.emerald, width: 1.25),
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.emerald,
          fontWeight: FontWeight.w700,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          backgroundColor: const WidgetStatePropertyAll(AppColors.darkSurface),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: AppColors.darkTextSecondary.withValues(alpha: 0.18),
            ),
          ),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        side: BorderSide.none,
        selectedColor: AppColors.emerald.withValues(alpha: 0.22),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(
            color: AppColors.darkTextSecondary.withValues(alpha: 0.18),
          ),
          backgroundColor: AppColors.darkSurfaceAlt,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(
              color: AppColors.darkTextSecondary.withValues(alpha: 0.2),
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        elevation: AppElevation.fab,
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final primary = brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondary = brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.6,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
    );
  }
}
