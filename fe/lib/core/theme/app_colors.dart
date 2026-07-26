import 'package:flutter/material.dart';

class AppColors {
  // === WALETA BRAND PALETTE (derived from logo) ===

  // Primary - Logo orange
  static const Color primary = Color(0xFFF9A825);         // logo orange
  static const Color primaryLight = Color(0xFFFBC02D);    // lighter orange
  static const Color primaryDark = Color(0xFFE8940C);     // deeper amber
  static const Color primarySoft = Color(0xFFFFF3CD);     // pale orange tint

  // Accent - Complementary warm tones
  static const Color accentGold = Color(0xFFFF8F00);      // deeper gold accent
  static const Color accentAmber = Color(0xFFFFCA28);     // bright highlight

  // Semantic
  static const Color income = Color(0xFF2E7D32);          // rich green for income
  static const Color incomeLight = Color(0xFFE8F5E9);     // green tint
  static const Color expense = Color(0xFFC62828);         // deep red for expense
  static const Color expenseLight = Color(0xFFFFEBEE);    // red tint
  static const Color warning = Color(0xFFFF8F00);         // amber warning
  static const Color error = Color(0xFFD32F2F);           // error red
  static const Color success = Color(0xFF2E7D32);         // success green

  // === LIGHT MODE ===
  static const Color lightBackground = Color(0xFFFFFBF2);   // warm cream
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFFFF8E6);   // warm card
  static const Color lightTextPrimary = Color(0xFF1A1209);  // warm near-black
  static const Color lightTextSecondary = Color(0xFF7D6E52); // warm brown-gray
  static const Color lightBorder = Color(0xFFEDE0C4);       // warm border
  static const Color lightMuted = Color(0xFFFFF3DC);        // warm muted bg
  static const Color lightDivider = Color(0xFFEDE0C4);

  // === DARK MODE ===
  static const Color darkBackground = Color(0xFF100E09);    // very dark warm
  static const Color darkSurface = Color(0xFF1E1A12);      // warm dark card
  static const Color darkSurfaceAlt = Color(0xFF26200F);   // elevated surface
  static const Color darkTextPrimary = Color(0xFFFFF8EE);  // warm off-white
  static const Color darkTextSecondary = Color(0xFFB89A6A); // warm gold-gray
  static const Color darkBorder = Color(0xFF3A3020);        // warm dark border
  static const Color darkMuted = Color(0xFF241E10);         // muted dark bg
  static const Color darkDivider = Color(0xFF3A3020);
}
