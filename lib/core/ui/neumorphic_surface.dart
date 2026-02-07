import 'package:flutter/material.dart';

class NeumorphicSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const NeumorphicSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          // luz superior
          BoxShadow(
            color: Colors.white10,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
          // sombra inferior
          BoxShadow(
            color: Colors.black54,
            offset: Offset(4, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: child,
    );
  }
}
