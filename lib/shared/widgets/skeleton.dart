import 'dart:math' as math;
import 'package:flutter/material.dart';

class Skeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant;
    final highlight = Theme.of(context).colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _ShimmerPainter(
              progress: _controller.value,
              base: base,
              highlight: highlight,
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color base;
  final Color highlight;

  _ShimmerPainter({
    required this.progress,
    required this.base,
    required this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradientWidth = size.width * 0.8;
    final dx = (size.width + gradientWidth) * progress - gradientWidth;

    final gradientRect = Rect.fromLTWH(dx, 0, gradientWidth, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          base,
          highlight.withOpacity(0.9),
          base,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(gradientRect);

    canvas.drawRect(rect, Paint()..color = base);
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.base != base ||
        oldDelegate.highlight != highlight;
  }
}
