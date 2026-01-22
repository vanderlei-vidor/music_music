import 'package:flutter/material.dart';

class VerticalVolumeSlider extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onChanged;

  const VerticalVolumeSlider({
    super.key,
    required this.volume,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: RotatedBox(
        quarterTurns: -1,
        child: Slider(
          value: volume,
          min: 0,
          max: 1,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
          inactiveColor: theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }
}
