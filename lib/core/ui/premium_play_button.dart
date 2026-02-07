import 'package:flutter/material.dart';
import 'package:music_music/core/theme/app_colors.dart';

class PremiumPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const PremiumPlayButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: PremiumGradients.accentOrange,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B2D).withOpacity(0.7),
              blurRadius: 28,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
