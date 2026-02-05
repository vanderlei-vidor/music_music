import 'package:flutter/material.dart';
import 'mini_equalizer.dart';

class PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final Color color;
  final double size;

  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    required this.color,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          );
        },
        child: Container(
          key: ValueKey(isPlaying),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          alignment: Alignment.center,
          child: isPlaying
              ? MiniEqualizer(
                  isPlaying: true,
                  color: Colors.white,
                )
              : Icon(
                  Icons.play_arrow,
                  size: size * 0.55,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
