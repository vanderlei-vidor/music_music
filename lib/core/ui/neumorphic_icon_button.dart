import 'package:flutter/material.dart';

class NeumorphicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          shape: BoxShape.circle,
          boxShadow: const [
            // luz superior
            BoxShadow(
              color: Colors.white12,
              offset: Offset(-3, -3),
              blurRadius: 6,
            ),
            // sombra inferior
            BoxShadow(
              color: Colors.black54,
              offset: Offset(3, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: size,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
