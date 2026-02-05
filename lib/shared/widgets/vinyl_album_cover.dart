import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'vinyl_needle.dart';

class VinylAlbumCover extends StatefulWidget {
  final String? artwork;
  final AudioPlayer player;
  final double size;

  const VinylAlbumCover({
    super.key,
    required this.artwork,
    required this.player,
    this.size = 190,
  });

  @override
  State<VinylAlbumCover> createState() => _VinylAlbumCoverState();
}

class _VinylAlbumCoverState extends State<VinylAlbumCover>
    with TickerProviderStateMixin {
  late AnimationController _diskController;
  late AnimationController _needleController;
  late Animation<double> _needleAnimation;

  late StreamSubscription<bool> _playingSub;
  late StreamSubscription<double> _speedSub;

  double _speed = 1.0;

  @override
  void initState() {
    super.initState();

    // 💿 DISCO (física livre)
    _diskController = AnimationController.unbounded(vsync: this);

    // 🎯 AGULHA
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _needleAnimation = CurvedAnimation(
      parent: _needleController,
      curve: Curves.easeOutCubic,
    );

    // ▶️ PLAY / PAUSE
    _playingSub = widget.player.playingStream.listen((playing) {
      if (playing) {
        _diskController.animateWith(
          _VinylSimulation(
            start: _diskController.value,
            velocity: 0.9 * _speed,
          ),
        );
        _needleController.forward();
      } else {
        _diskController.animateWith(
          _VinylSimulation(
            start: _diskController.value,
            velocity: 0.2, // inércia real
            friction: 0.18,
          ),
        );
        _needleController.reverse();
      }
    });

    // 🎚️ VELOCIDADE
    _speedSub = widget.player.speedStream.listen((s) {
      _speed = s;
    });
  }

  @override
  void dispose() {
    _playingSub.cancel();
    _speedSub.cancel();
    _diskController.dispose();
    _needleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 💿 DISCO GIRANDO
        AnimatedBuilder(
          animation: _diskController,
          builder: (_, __) {
            return Transform.rotate(
              angle: _diskController.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // BASE DO VINIL
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                  ),

                  // SULCOS
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _VinylGroovesPainter(),
                  ),

                  // RÓTULO CENTRAL
                  Container(
                    width: widget.size * 0.45,
                    height: widget.size * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: widget.artwork != null
                          ? DecorationImage(
                              image: NetworkImage(widget.artwork!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  // HIGHLIGHT
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                        center: const Alignment(-0.4, -0.6),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // 🎯 AGULHA (NÃO GIRA)
        Positioned(
          top: -widget.size * 0.12,
          right: -widget.size * 0.15,
          child: VinylNeedle(
            animation: _needleAnimation,
            size: widget.size,
          ),
        ),
      ],
    );
  }
}

// ===============================
// 🎢 SIMULAÇÃO DE FÍSICA DO VINIL
// ===============================
class _VinylSimulation extends Simulation {
  final double start;
  final double velocity;
  final double friction;

  _VinylSimulation({
    required this.start,
    required this.velocity,
    this.friction = 0.02,
  });

  @override
  double x(double time) => start + velocity * time;

  @override
  double dx(double time) => velocity * exp(-friction * time);

  @override
  bool isDone(double time) => dx(time).abs() < 0.001;
}

// ===============================
// 🎵 SULCOS DO VINIL
// ===============================
class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.05);

    for (double r = size.width * 0.25; r < size.width * 0.5; r += 2.5) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
