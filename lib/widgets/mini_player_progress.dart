import 'package:flutter/material.dart';

class MiniPlayerProgress extends StatelessWidget {
  final double progress; // 0.0 → 1.0
  final Color color;

  const MiniPlayerProgress({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(20),
      ),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 2.5,
        backgroundColor: color.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
