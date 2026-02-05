import 'package:flutter/material.dart';

class PlaylistPlayShuffleButton extends StatelessWidget {
  final bool isPlaying;
  final bool isShuffled;
  final VoidCallback onPlayPause;
  final VoidCallback onShuffle;

  const PlaylistPlayShuffleButton({
    super.key,
    required this.isPlaying,
    required this.isShuffled,
    required this.onPlayPause,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor = isShuffled
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;

    final iconColor = isShuffled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ▶️ PLAY / PAUSE — MORPH ANIMADO
          GestureDetector(
            onTap: onPlayPause,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns:
                      Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.85,
                      end: 1.0,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  ),
                );
              },
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                key: ValueKey(isPlaying),
                size: 30,
                color: iconColor,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // 🔁 SHUFFLE — ROTATION ANIMADA
          IconButton(
            icon: AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: isShuffled ? 0.25 : 0,
              curve: Curves.easeOutCubic,
              child: Icon(
                Icons.shuffle_rounded,
                size: 24,
                color: iconColor,
              ),
            ),
            onPressed: onShuffle,
          ),
        ],
      ),
    );
  }
}

class _PulsingShuffleButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _PulsingShuffleButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_PulsingShuffleButton> createState() => _PulsingShuffleButtonState();
}

class _PulsingShuffleButtonState extends State<_PulsingShuffleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingShuffleButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glowStrength = widget.isActive
              ? 0.4 + (_controller.value * 0.4)
              : 0.0;

          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary
                            .withOpacity(glowStrength),
                        blurRadius: 20 + (_controller.value * 12),
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: widget.isActive ? 1.05 : 1.0,
              curve: Curves.easeOutCubic,
              child: Icon(
                Icons.shuffle_rounded,
                size: 24,
                color: widget.isActive
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}
