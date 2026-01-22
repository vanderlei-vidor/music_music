import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShuffleButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const ShuffleButton({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.45),
                    blurRadius: 14,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            Icons.shuffle,
            key: ValueKey(isActive), // 🔥 ESSENCIAL
            size: 26,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
