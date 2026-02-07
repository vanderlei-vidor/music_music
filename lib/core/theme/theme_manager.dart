// lib/core/theme/theme_manager.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_music/core/theme/app_styles.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class ThemeManager with ChangeNotifier {
  ThemePreset _preset;

  ThemePreset get preset => _preset;

  ThemeMode get themeMode =>
      _preset == ThemePreset.neumorphicDark ? ThemeMode.dark : ThemeMode.light;

  ThemeManager({ThemePreset? initialPreset})
    : _preset = initialPreset ?? ThemePreset.whiteMinimal;

  void setPreset(ThemePreset value) {
    if (_preset == value) return;
    _preset = value;
    _persistPreset();
    notifyListeners();
  }

  ThemeData get themeData =>
      _preset == ThemePreset.neumorphicDark ? darkTheme : lightTheme;

  static Future<ThemePreset> loadPreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_prefsKey) ?? ThemePreset.whiteMinimal.index;
      return ThemePreset.values[saved.clamp(0, ThemePreset.values.length - 1)];
    } catch (_) {
      return ThemePreset.whiteMinimal;
    }
  }

  Future<void> _persistPreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, _preset.index);
    } catch (_) {
      // ignore: best-effort persistence
    }
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final inter = GoogleFonts.interTextTheme(base.textTheme);
    final fraunces = GoogleFonts.frauncesTextTheme(base.textTheme);

    final textTheme = inter.copyWith(
      displayLarge: fraunces.displayLarge,
      displayMedium: fraunces.displayMedium,
      displaySmall: fraunces.displaySmall,
      headlineLarge: fraunces.headlineLarge,
      headlineMedium: fraunces.headlineMedium,
      headlineSmall: fraunces.headlineSmall,
      titleLarge: inter.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: inter.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: inter.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: inter.bodyMedium?.copyWith(height: 1.35),
      labelLarge: inter.labelLarge?.copyWith(letterSpacing: 0.2),
    );

    return base.copyWith(
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
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: LightColors.background,
        foregroundColor: LightColors.onBackground,
      ),
      cardColor: LightColors.cardBackground,
      cardTheme: CardThemeData(
        color: LightColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: LightColors.onSurface,
        textColor: LightColors.onSurface,
      ),
      extensions: <ThemeExtension<dynamic>>[
        const AppStyles(
          mainGradient: null,
          premiumShadow: BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ),
        const AppShadows(
          surface: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
          elevated: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
          neumorphic: [
            BoxShadow(
              color: Color(0x33FFFFFF),
              blurRadius: 12,
              offset: Offset(-4, -4),
            ),
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(4, 4),
            ),
          ],
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final inter = GoogleFonts.interTextTheme(base.textTheme);
    final fraunces = GoogleFonts.frauncesTextTheme(base.textTheme);

    final textTheme = inter.copyWith(
      displayLarge: fraunces.displayLarge,
      displayMedium: fraunces.displayMedium,
      displaySmall: fraunces.displaySmall,
      headlineLarge: fraunces.headlineLarge,
      headlineMedium: fraunces.headlineMedium,
      headlineSmall: fraunces.headlineSmall,
      titleLarge: inter.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: inter.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: inter.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: inter.bodyMedium?.copyWith(height: 1.35),
      labelLarge: inter.labelLarge?.copyWith(letterSpacing: 0.2),
    );

    return base.copyWith(
      scaffoldBackgroundColor: NeumorphicDarkColors.background,
      colorScheme: const ColorScheme.dark(
        primary: NeumorphicDarkColors.primary,
        onPrimary: NeumorphicDarkColors.onPrimary,
        secondary: NeumorphicDarkColors.secondary,
        onSecondary: NeumorphicDarkColors.onSecondary,
        background: NeumorphicDarkColors.background,
        onBackground: NeumorphicDarkColors.onBackground,
        surface: NeumorphicDarkColors.surface,
        onSurface: NeumorphicDarkColors.onSurface,
        error: NeumorphicDarkColors.error,
        onError: NeumorphicDarkColors.onError,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: NeumorphicDarkColors.background,
        foregroundColor: NeumorphicDarkColors.onBackground,
      ),
      cardColor: NeumorphicDarkColors.cardBackground,
      cardTheme: CardThemeData(
        color: NeumorphicDarkColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeumorphicDarkColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: NeumorphicDarkColors.onSurface,
        textColor: NeumorphicDarkColors.onSurface,
      ),
      extensions: <ThemeExtension<dynamic>>[
        const AppStyles(
          mainGradient: PremiumGradients.darkLiquid,
          premiumShadow: BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ),
        const AppShadows(
          surface: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
          elevated: [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
          neumorphic: [
            BoxShadow(
              color: Color(0x1FFFFFFF),
              blurRadius: 16,
              offset: Offset(-6, -6),
            ),
            BoxShadow(
              color: Color(0x5C000000),
              blurRadius: 16,
              offset: Offset(6, 6),
            ),
          ],
        ),
      ],
    );
  }
}

enum ThemePreset { whiteMinimal, neumorphicDark }

const String _prefsKey = 'theme_preset';
