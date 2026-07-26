import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextTheme get lightTextTheme {
    return TextTheme(
      displayLarge: _inter(size: 28, weight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.5),
      displayMedium: _inter(size: 22, weight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.3),
      titleLarge: _inter(size: 18, weight: FontWeight.w600, color: AppColors.lightTextPrimary),
      titleMedium: _inter(size: 16, weight: FontWeight.w600, color: AppColors.lightTextPrimary),
      titleSmall: _inter(size: 14, weight: FontWeight.w600, color: AppColors.lightTextPrimary),
      bodyLarge: _inter(size: 15, weight: FontWeight.w400, color: AppColors.lightTextPrimary),
      bodyMedium: _inter(size: 13, weight: FontWeight.w400, color: AppColors.lightTextSecondary),
      bodySmall: _inter(size: 12, weight: FontWeight.w400, color: AppColors.lightTextSecondary),
      labelLarge: _inter(size: 14, weight: FontWeight.w500, color: AppColors.lightTextPrimary),
      labelMedium: _inter(size: 12, weight: FontWeight.w500, color: AppColors.lightTextSecondary),
      labelSmall: _inter(size: 11, weight: FontWeight.w500, color: AppColors.lightTextSecondary),
    );
  }

  static TextTheme get darkTextTheme {
    return TextTheme(
      displayLarge: _inter(size: 28, weight: FontWeight.w700, color: AppColors.darkTextPrimary, letterSpacing: -0.5),
      displayMedium: _inter(size: 22, weight: FontWeight.w700, color: AppColors.darkTextPrimary, letterSpacing: -0.3),
      titleLarge: _inter(size: 18, weight: FontWeight.w600, color: AppColors.darkTextPrimary),
      titleMedium: _inter(size: 16, weight: FontWeight.w600, color: AppColors.darkTextPrimary),
      titleSmall: _inter(size: 14, weight: FontWeight.w600, color: AppColors.darkTextPrimary),
      bodyLarge: _inter(size: 15, weight: FontWeight.w400, color: AppColors.darkTextPrimary),
      bodyMedium: _inter(size: 13, weight: FontWeight.w400, color: AppColors.darkTextSecondary),
      bodySmall: _inter(size: 12, weight: FontWeight.w400, color: AppColors.darkTextSecondary),
      labelLarge: _inter(size: 14, weight: FontWeight.w500, color: AppColors.darkTextPrimary),
      labelMedium: _inter(size: 12, weight: FontWeight.w500, color: AppColors.darkTextSecondary),
      labelSmall: _inter(size: 11, weight: FontWeight.w500, color: AppColors.darkTextSecondary),
    );
  }
}
