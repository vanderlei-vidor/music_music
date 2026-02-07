import 'package:flutter/material.dart';

class AppShadows extends ThemeExtension<AppShadows> {
  final List<BoxShadow> surface;
  final List<BoxShadow> elevated;
  final List<BoxShadow> neumorphic;

  const AppShadows({
    required this.surface,
    required this.elevated,
    required this.neumorphic,
  });

  @override
  AppShadows copyWith({
    List<BoxShadow>? surface,
    List<BoxShadow>? elevated,
    List<BoxShadow>? neumorphic,
  }) {
    return AppShadows(
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      neumorphic: neumorphic ?? this.neumorphic,
    );
  }

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    return AppShadows(
      surface: BoxShadow.lerpList(surface, other.surface, t) ?? surface,
      elevated: BoxShadow.lerpList(elevated, other.elevated, t) ?? elevated,
      neumorphic:
          BoxShadow.lerpList(neumorphic, other.neumorphic, t) ?? neumorphic,
    );
  }
}
