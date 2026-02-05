import 'package:flutter/material.dart';

class SpeedButton extends StatelessWidget {
  final double speed;
  final VoidCallback onTap;

  const SpeedButton({
    super.key,
    required this.speed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '${speed.toStringAsFixed(2)}x',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


class SpeedSheet extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onChanged;

  const SpeedSheet({
    super.key,
    required this.currentSpeed,
    required this.onChanged,
  });

  static const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Velocidade',
            style: theme.textTheme.titleMedium,
          ),

          const SizedBox(height: 20),

          // 🎚️ SLIDER
          Slider(
            min: 0.5,
            max: 2.0,
            divisions: 6,
            value: currentSpeed,
            label: '${currentSpeed.toStringAsFixed(2)}x',
            onChanged: onChanged,
          ),

          const SizedBox(height: 16),

          // ⚡ PRESETS
          Wrap(
            spacing: 10,
            children: speeds.map((s) {
              final isActive = s == currentSpeed;

              return GestureDetector(
                onTap: () => onChanged(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                  ),
                  child: Text(
                    '${s}x',
                    style: TextStyle(
                      color: isActive
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
