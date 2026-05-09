import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendly/core/theme/app_design_tokens.dart';

class AppTypography {
  static const String headingFamily = 'Bricolage Grotesque';
  static const String bodyFamily = 'Inter';

  static TextTheme textTheme(Brightness brightness) {
    final primary = brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondary = brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return TextTheme(
      headlineLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        height: 1.18,
        color: primary,
      ),
      headlineMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        height: 1.2,
        color: primary,
      ),
      titleLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1.24,
        color: primary,
      ),
      titleMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.24,
        color: primary,
      ),
      titleSmall: GoogleFonts.bricolageGrotesque(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.24,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: secondary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.48,
        color: secondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.42,
        color: secondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        height: 1.35,
        color: secondary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        height: 1.35,
        color: secondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.45,
        height: 1.3,
        color: secondary,
      ),
    );
  }

  static TextStyle amountStyle(Color color) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color,
  );
}
