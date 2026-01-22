import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedFavoriteIcon extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final double size;
  final Color? activeColor; // 🆕 cor customizável

  const AnimatedFavoriteIcon({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = 32,
    this.activeColor,
  });

  @override
  State<AnimatedFavoriteIcon> createState() => _AnimatedFavoriteIconState();
}

class _HeartBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount = 8;

  _HeartBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * progress * 1.6;

    final paint = Paint()
      ..color = color.withOpacity(1 - progress)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final angle = (2 * pi / particleCount) * i;
      final offset = Offset(cos(angle) * radius, sin(angle) * radius);

      canvas.drawCircle(center + offset, 3 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _AnimatedFavoriteIconState extends State<AnimatedFavoriteIcon>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _burstController;
  late AnimationController _unfavoriteController;
  late Animation<double> _shrinkAnimation;

  late Animation<double> _scale;
  late Animation<double> _burst;

  @override
  void initState() {
    super.initState();

    _unfavoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _shrinkAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _unfavoriteController, curve: Curves.easeInOut),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _scale = Tween(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _burst = CurvedAnimation(
      parent: _burstController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedFavoriteIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔥 só explode quando FAVORITA
    if (!oldWidget.isFavorite && widget.isFavorite) {
      
      _scaleController.forward(from: 0);
      _burstController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _playUnfavoriteAnimation(); 
    _scaleController.dispose();

    _burstController.dispose();
    super.dispose();
  }

  ThemeData get theme => Theme.of(context);

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor =
        widget.activeColor ??
        (theme.brightness == Brightness.dark
            ? Colors.redAccent.shade200
            : Colors.redAccent.shade400);
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size + 20,
        height: widget.size + 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✨ PARTÍCULAS
            AnimatedBuilder(
              animation: _burst,
              builder: (_, __) {
                return IgnorePointer(
                  child: CustomPaint(
                    painter: _HeartBurstPainter(
                      progress: _burst.value,
                      color: resolvedColor,
                    ),
                    size: Size.square(widget.size + 20),
                  ),
                );
              },
            ),

            // ❤️ CORAÇÃO
            ScaleTransition(
              scale: _scale,
              child: 
              Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: widget.size,
                color: widget.isFavorite
                    ? resolvedColor
                    : theme.colorScheme.onSurface,
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  void _playUnfavoriteAnimation() {
    _unfavoriteController.forward(from: 0).then((_) {
      _unfavoriteController.reverse();
    });
  }
}
