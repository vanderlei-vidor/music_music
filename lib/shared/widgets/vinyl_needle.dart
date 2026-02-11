import 'dart:ui';

import 'package:flutter/material.dart';

class VinylNeedle extends StatelessWidget {
  final Animation<double> animation;
  final double size;

  const VinylNeedle({
    super.key,
    required this.animation,
    this.size = 190,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Transform.rotate(
          angle: lerpDouble(-0.45, -0.15, animation.value)!,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                // BASE DA AGULHA
                Positioned(
                  left: size * 0.05,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                  ),
                ),

                // BRAÇO
                Positioned(
                  left: size * 0.09,
                  top: 6,
                  child: Container(
                    width: 4,
                    height: size * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // CABEÇA
                Positioned(
                  left: size * 0.03,
                  top: size * 0.7,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
