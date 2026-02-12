import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class RepeatButton extends StatelessWidget {
  final LoopMode mode;
  final VoidCallback onTap;

  const RepeatButton({
    super.key,
    required this.mode,
    required this.onTap,
  });

  IconData get _icon {
    switch (mode) {
      case LoopMode.one:
        return Icons.repeat_one;
      case LoopMode.all:
        return Icons.repeat;
      default:
        return Icons.repeat;
    }
  }

  Color _color(BuildContext context) {
    final theme = Theme.of(context);

    if (mode == LoopMode.off) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.4);
    }

    return theme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: mode == LoopMode.off
              ? []
              : [
                  BoxShadow(
                    color: _color(context).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: AnimatedScale(
          scale: mode == LoopMode.off ? 1.0 : 1.12,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Icon(
            _icon,
            size: 30,
            color: _color(context),
          ),
        ),
      ),
    );
  }
}

