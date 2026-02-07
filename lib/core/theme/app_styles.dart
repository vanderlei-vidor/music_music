import 'package:flutter/material.dart';

@immutable
class AppStyles extends ThemeExtension<AppStyles> {
  final Gradient? mainGradient;
  final BoxShadow? premiumShadow;

  const AppStyles({
    this.mainGradient,
    this.premiumShadow,
  });

  @override
  AppStyles copyWith({
    Gradient? mainGradient,
    BoxShadow? premiumShadow,
  }) {
    return AppStyles(
      mainGradient: mainGradient ?? this.mainGradient,
      premiumShadow: premiumShadow ?? this.premiumShadow,
    );
  }

  @override
  AppStyles lerp(ThemeExtension<AppStyles>? other, double t) {
    if (other is! AppStyles) return this;
    return AppStyles(
      mainGradient: Gradient.lerp(mainGradient, other.mainGradient, t),
      premiumShadow: BoxShadow.lerp(premiumShadow, other.premiumShadow, t),
    );
  }
}
