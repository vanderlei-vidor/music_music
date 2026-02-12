import 'package:flutter/material.dart';

class MiniProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Color color;

  const MiniProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds;
    final current = position.inMilliseconds.clamp(0, total);

    final progress = total == 0 ? 0.0 : current / total;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: progress),
          builder: (_, value, __) {
            return LinearProgressIndicator(
              value: value,
              minHeight: 3,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            );
          },
        ),
      ),
    );
  }
}

