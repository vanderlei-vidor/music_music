import 'dart:math';
import 'package:flutter/material.dart';

class VolumeEqualizer extends StatelessWidget {
  final double volume;
  final int barCount;
  final double height;

  const VolumeEqualizer({
    super.key,
    required this.volume,
    this.barCount = 5,
    this.height = 24,
  });

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(barCount, (index) {
      final double factor = 0.3 + (index / barCount);

      final double barHeight = max(
        4.0,
        volume * height * factor,
      );

      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 4,
        height: barHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }),
  );
}

}
