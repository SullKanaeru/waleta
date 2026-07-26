import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextTheme get lightTextTheme {
    return TextTheme(
      displayLarge: _jakarta(size: 32, weight: FontWeight.w800, color: AppColors.lightTextPrimary, letterSpacing: -1.2, height: 1.1),
      displayMedium: _jakarta(size: 26, weight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.8, height: 1.2),
      titleLarge: _jakarta(size: 19, weight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.4),
      titleMedium: _jakarta(size: 15, weight: FontWeight.w600, color: AppColors.lightTextPrimary, letterSpacing: -0.1),
      titleSmall: _jakarta(size: 14, weight: FontWeight.w600, color: AppColors.lightTextPrimary),
      bodyLarge: _jakarta(size: 15, weight: FontWeight.w400, color: AppColors.lightTextPrimary, height: 1.65),
      bodyMedium: _jakarta(size: 13, weight: FontWeight.w400, color: AppColors.lightTextSecondary, height: 1.6),
      bodySmall: _jakarta(size: 12, weight: FontWeight.w400, color: AppColors.lightTextSecondary, height: 1.5),
      labelLarge: _jakarta(size: 13, weight: FontWeight.w600, color: AppColors.lightTextPrimary),
      labelMedium: _jakarta(size: 11, weight: FontWeight.w500, color: AppColors.lightTextSecondary, letterSpacing: 0.1),
      labelSmall: _jakarta(size: 10, weight: FontWeight.w500, color: AppColors.lightTextSecondary, letterSpacing: 0.2),
    );
  }

  static TextTheme get darkTextTheme {
    return TextTheme(
      displayLarge: _jakarta(size: 32, weight: FontWeight.w800, color: AppColors.darkTextPrimary, letterSpacing: -1.2, height: 1.1),
      displayMedium: _jakarta(size: 26, weight: FontWeight.w700, color: AppColors.darkTextPrimary, letterSpacing: -0.8, height: 1.2),
      titleLarge: _jakarta(size: 19, weight: FontWeight.w700, color: AppColors.darkTextPrimary, letterSpacing: -0.4),
      titleMedium: _jakarta(size: 15, weight: FontWeight.w600, color: AppColors.darkTextPrimary, letterSpacing: -0.1),
      titleSmall: _jakarta(size: 14, weight: FontWeight.w600, color: AppColors.darkTextPrimary),
      bodyLarge: _jakarta(size: 15, weight: FontWeight.w400, color: AppColors.darkTextPrimary, height: 1.65),
      bodyMedium: _jakarta(size: 13, weight: FontWeight.w400, color: AppColors.darkTextSecondary, height: 1.6),
      bodySmall: _jakarta(size: 12, weight: FontWeight.w400, color: AppColors.darkTextSecondary, height: 1.5),
      labelLarge: _jakarta(size: 13, weight: FontWeight.w600, color: AppColors.darkTextPrimary),
      labelMedium: _jakarta(size: 11, weight: FontWeight.w500, color: AppColors.darkTextSecondary, letterSpacing: 0.1),
      labelSmall: _jakarta(size: 10, weight: FontWeight.w500, color: AppColors.darkTextSecondary, letterSpacing: 0.2),
    );
  }
}
