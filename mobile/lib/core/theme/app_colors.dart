import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette (from design reference)
  static const Color primary = Color(0xFFC8FF00);
  static const Color primaryDark = Color(0xFF9ECC00);
  static const Color primaryLight = Color(0xFFE0FF66);

  // Backgrounds
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF222222);
  static const Color surfaceBorder = Color(0xFF2A2A2A);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textTertiary = Color(0xFF666666);
  static const Color textOnPrimary = Color(0xFF0D0D0D);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // Semantic
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFEF5350);
  static const Color goalProgress = primary;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC8FF00), Color(0xFF9ECC00)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A2A1A), Color(0xFF0D0D0D)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F1F1F), Color(0xFF161616)],
  );
}
