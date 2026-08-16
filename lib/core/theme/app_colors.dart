import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents (Champagne Rose Gold & Warm Amber)
  static const Color champagne = Color(0xFFE8C39E);
  static const Color champagneLight = Color(0xFFF7E7D4);
  static const Color champagneDark = Color(0xFFC49A70);
  
  static const Color roseDust = Color(0xFFD98880);
  static const Color roseGlow = Color(0xFFE5989B);
  static const Color warmCopper = Color(0xFFB56576);

  // Dark Theme Palette (Obsidian & Deep Charcoal)
  static const Color darkBackground = Color(0xFF0D0F15);
  static const Color darkSurface = Color(0xFF161922);
  static const Color darkSurfaceElevated = Color(0xFF1F2330);
  static const Color darkCard = Color(0xFF1A1D28);
  static const Color darkBorder = Color(0xFF2B3042);

  // Light Theme Palette (Warm Cream & Pearl)
  static const Color lightBackground = Color(0xFFFBF9F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF4F0E8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6E1D8);

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF1F3F9);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);

  static const Color textPrimaryLight = Color(0xFF1E2430);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // Status & Utility Colors
  static const Color success = Color(0xFF52B788);
  static const Color error = Color(0xFFE63946);
  static const Color warning = Color(0xFFF4A261);
  static const Color info = Color(0xFF457B9D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE8C39E), Color(0xFFD98880)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A1D28), Color(0xFF141720)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0AFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
