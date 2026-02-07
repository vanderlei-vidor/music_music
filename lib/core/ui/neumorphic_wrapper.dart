import 'package:flutter/material.dart';

class NeumorphicWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsets padding;

  const NeumorphicWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 16,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: Colors.white12,
              offset: Offset(-3, -3),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.black54,
              offset: Offset(3, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
