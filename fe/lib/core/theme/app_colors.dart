import 'package:flutter/material.dart';

class AppColors {
  // === WALETA BRAND PALETTE ===

  // Primary — Brand amber/gold
  static const Color primary = Color(0xFFF5A623);          // warm amber (slightly desaturated)
  static const Color primaryLight = Color(0xFFF7B84B);     // lighter amber
  static const Color primaryDark = Color(0xFFE09200);      // deeper gold
  static const Color primarySoft = Color(0xFFFEF3E0);      // very pale amber tint

  // Accent
  static const Color accentGold = Color(0xFFFF9500);       // deeper gold
  static const Color accentAmber = Color(0xFFFFBD00);      // bright highlight

  // Semantic
  static const Color income = Color(0xFF1A7A4A);           // forest green — income
  static const Color incomeLight = Color(0xFFEAF6F0);      // green tint
  static const Color expense = Color(0xFFB83232);          // deep crimson — expense
  static const Color expenseLight = Color(0xFFFBECEC);     // red tint
  static const Color warning = Color(0xFFE67E00);          // amber warning
  static const Color error = Color(0xFFCF3030);            // error red
  static const Color success = Color(0xFF1A7A4A);          // success green

  // === LIGHT MODE ===
  // Goal: ultra-clean, neutral warmth, feels premium
  static const Color lightBackground = Color(0xFFF7F6F4);  // warm off-white (very subtle)
  static const Color lightSurface = Color(0xFFFFFFFF);     // pure white
  static const Color lightSurfaceAlt = Color(0xFFF2F1EF);  // light grey card
  static const Color lightTextPrimary = Color(0xFF141414); // near-black
  static const Color lightTextSecondary = Color(0xFF8C8C8C); // neutral grey
  static const Color lightBorder = Color(0xFFE8E8E8);      // clean light grey border
  static const Color lightMuted = Color(0xFFF4F4F4);       // muted fill
  static const Color lightDivider = Color(0xFFEEEEEE);

  // === DARK MODE ===
  // Goal: deep neutral near-black, not brownish
  static const Color darkBackground = Color(0xFF0F0F11);   // near-black neutral
  static const Color darkSurface = Color(0xFF1A1A1E);      // elevated surface
  static const Color darkSurfaceAlt = Color(0xFF222228);   // card elevated
  static const Color darkTextPrimary = Color(0xFFF5F5F5);  // clean off-white
  static const Color darkTextSecondary = Color(0xFF888890); // muted grey
  static const Color darkBorder = Color(0xFF2C2C34);       // subtle border
  static const Color darkMuted = Color(0xFF1E1E24);        // muted dark bg
  static const Color darkDivider = Color(0xFF2A2A30);
}
