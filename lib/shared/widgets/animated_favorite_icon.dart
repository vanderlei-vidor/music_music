import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedFavoriteIcon extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final double size;
  final Color? activeColor;

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

class _AnimatedFavoriteIconState extends State<AnimatedFavoriteIcon>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _burstController;
  late AnimationController _unfavoriteController;

  late Animation<double> _scale;
  late Animation<double> _burst;
  late Animation<double> _shrink;

  @override
  void initState() {
    super.initState();

    // 1. Controller para quando desfavorita (Shrink/Encolher)
    _unfavoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _shrink = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _unfavoriteController, curve: Curves.easeInOut),
    );

    // 2. Controller para quando favorita (Scale Up)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _scale = Tween(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // 3. Controller para a explosÃ£o de partÃ­culas
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _burst = CurvedAnimation(
      parent: _burstController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedFavoriteIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isFavorite && widget.isFavorite) {
      // ðŸ”¥ FAVORITOU: Explode e aumenta
      _scaleController.forward(from: 0);
      _burstController.forward(from: 0);
    } else if (oldWidget.isFavorite && !widget.isFavorite) {
      // ðŸ§Š DESFAVORITOU: Pequeno pulso de encolhimento
      _unfavoriteController.forward(from: 0).then((_) => _unfavoriteController.reverse());
    }
  }

  @override
  void dispose() {
    // IMPORTANTE: Todos os controllers devem ser descartados aqui!
    _unfavoriteController.dispose();
    _scaleController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color resolvedColor = widget.activeColor ??
        (theme.brightness == Brightness.dark
            ? Colors.redAccent.shade200
            : Colors.redAccent.shade400);

    return GestureDetector(
      onTap: () {
        // ðŸ“³ FEEDBACK TÃTIL (VibraÃ§Ã£o)
        if (!widget.isFavorite) {
          HapticFeedback.mediumImpact(); // VibraÃ§Ã£o firme ao favoritar
        } else {
          HapticFeedback.selectionClick(); // Toque sutil ao desfavoritar
        }
        
        widget.onTap(); // Executa a funÃ§Ã£o original
      },
      child: SizedBox(
        width: widget.size + 20,
        height: widget.size + 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // âœ¨ PARTÃCULAS
            AnimatedBuilder(
              animation: _burst,
              builder: (_, __) => IgnorePointer(
                child: CustomPaint(
                  painter: _HeartBurstPainter(
                    progress: _burst.value,
                    color: resolvedColor,
                  ),
                  size: Size.square(widget.size + 20),
                ),
              ),
            ),

            // â¤ï¸ CORAÃ‡ÃƒO COM DUPLA ANIMAÃ‡ÃƒO + GLOW (Brilho)
            ScaleTransition(
              scale: widget.isFavorite ? _scale : _shrink,
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: widget.size,
                color: widget.isFavorite
                    ? resolvedColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                // ðŸŒŸ Adicionando o efeito de Glow quando favoritado
                shadows: widget.isFavorite 
                  ? [
                      Shadow(
                        color: resolvedColor.withValues(alpha: 0.8),
                        blurRadius: 15,
                        offset: const Offset(0, 0),
                      ),
                      Shadow(
                        color: resolvedColor.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 0),
                      ),
                    ] 
                  : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// O Painter das partÃ­culas continua igual (estÃ¡ correto)
class _HeartBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount = 8;

  _HeartBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * progress * 1.6;

    final paint = Paint()
      ..color = color.withValues(alpha: 1 - progress)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final angle = (2 * pi / particleCount) * i;
      final offset = Offset(cos(angle) * radius, sin(angle) * radius);
      canvas.drawCircle(center + offset, 3 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
