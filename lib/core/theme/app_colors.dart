// core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// ===============================
/// 🎨 GRADIENTS PREMIUM
/// ===============================
class PremiumGradients {
  static const LinearGradient darkLiquid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF232931),
      Color(0xFF121417),
    ],
  );

  static const LinearGradient accentOrange = LinearGradient(
    colors: [
      Color(0xFFFF6B2D),
      Color(0xFFFF912D),
    ],
  );

  static const LinearGradient glassWhite = LinearGradient(
    colors: [
      Colors.white24,
      Colors.white10,
    ],
  );
}

/// ===============================
/// 🌞 LIGHT THEME COLORS
/// ===============================
class LightColors {
  static const Color primary = Color(0xFF1E5BFF);
  static const Color onPrimary = Colors.white;
  static const Color secondary = Color(0xFF0E9F9A);
  static const Color onSecondary = Colors.white;
  static const Color background = Color(0xFFF6F5F2);
  static const Color onBackground = Color(0xFF111111);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF121212);
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Colors.white;
  static const Color cardBackground = Color(0xFFF2F1ED);
}

/// ===============================
/// 🌙 NEUMORPHIC DARK COLORS (PREMIUM)
/// ===============================
class NeumorphicDarkColors {
  static const Color primary = Color(0xFFFF6B2D);
  static const Color onPrimary = Color(0xFF0E0F11);
  static const Color secondary = Color(0xFF3E434B);
  static const Color onSecondary = Color(0xFFEAEAEA);
  static const Color background = Color(0xFF121417); // MAIS PROFUNDO
  static const Color onBackground = Color(0xFFEFEFEF);
  static const Color surface = Color(0xFF1C1F26);
  static const Color onSurface = Color(0xFFE6E6E6);
  static const Color error = Color(0xFFF2B8B5);
  static const Color onError = Color(0xFF0E0F11);
  static const Color cardBackground = Color(0xFF22272E);
}
