// lib/core/theme/theme_manager.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  static ThemeData get lightTheme {
    return ThemeData.light(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: LightColors.background,
      colorScheme: const ColorScheme.light(
        primary: LightColors.primary,
        onPrimary: LightColors.onPrimary,
        secondary: LightColors.secondary,
        onSecondary: LightColors.onSecondary,
        background: LightColors.background,
        onBackground: LightColors.onBackground,
        surface: LightColors.surface,
        onSurface: LightColors.onSurface,
        error: LightColors.error,
        onError: LightColors.onError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LightColors.background,
        foregroundColor: LightColors.onBackground,
      ),
      cardColor: LightColors.cardBackground,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: DarkColors.background,
      colorScheme: const ColorScheme.dark(
        primary: DarkColors.primary,
        onPrimary: DarkColors.onPrimary,
        secondary: DarkColors.secondary,
        onSecondary: DarkColors.onSecondary,
        background: DarkColors.background,
        onBackground: DarkColors.onBackground,
        surface: DarkColors.surface,
        onSurface: DarkColors.onSurface,
        error: DarkColors.error,
        onError: DarkColors.onError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DarkColors.background,
        foregroundColor: DarkColors.onBackground,
      ),
      cardColor: DarkColors.cardBackground,
    );
  }
}