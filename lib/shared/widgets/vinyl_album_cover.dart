import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music_music/shared/widgets/artwork_image.dart';
import 'vinyl_needle.dart';

class VinylAlbumCover extends StatefulWidget {
  final String? artwork;
  final int? audioId;
  final AudioPlayer player;
  final double size;
  final bool showNeedle;
  final double motionProgress;

  const VinylAlbumCover({
    super.key,
    required this.artwork,
    this.audioId,
    required this.player,
    this.size = 190,
    this.showNeedle = true,
    this.motionProgress = 1.0,
  });

  @override
  State<VinylAlbumCover> createState() => _VinylAlbumCoverState();
}

class _VinylAlbumCoverState extends State<VinylAlbumCover>
    with TickerProviderStateMixin {
  late AnimationController _diskController;
  late AnimationController _needleController;
  late AnimationController _velocityController;
  late Animation<double> _needleAnimation;
  late final Ticker _spinTicker;

  late StreamSubscription<bool> _playingSub;
  late StreamSubscription<double> _speedSub;

  double _speed = 1.0;
  double _angle = 0.0;
  double _angularVelocity = 0.0;
  bool _isPlaying = false;
  Duration? _lastTick;
  VoidCallback? _velocityListener;

  @override
  void initState() {
    super.initState();

    _diskController = AnimationController.unbounded(vsync: this);

    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _velocityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _needleAnimation = CurvedAnimation(
      parent: _needleController,
      curve: Curves.easeOutCubic,
    );

    _spinTicker = createTicker(_onTick)..start();

    _playingSub = widget.player.playingStream.listen((playing) {
      _isPlaying = playing;
      if (playing) {
        _retargetVelocity(animate: true);
        _needleController.forward();
      } else {
        _retargetVelocity(animate: true);
        _needleController.reverse();
      }
    });

    _speedSub = widget.player.speedStream.listen((s) {
      _speed = s;
      _retargetVelocity(animate: true);
    });

    _isPlaying = widget.player.playing;
    _retargetVelocity(animate: false);
  }

  @override
  void didUpdateWidget(covariant VinylAlbumCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionProgress != widget.motionProgress) {
      _retargetVelocity(animate: true);
    }
  }

  @override
  void dispose() {
    _playingSub.cancel();
    _speedSub.cancel();
    _spinTicker.dispose();
    final listener = _velocityListener;
    if (listener != null) {
      _velocityController.removeListener(listener);
      _velocityListener = null;
    }
    _velocityController.dispose();
    _diskController.dispose();
    _needleController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final dt = (elapsed - last).inMicroseconds / 1000000.0;
    if (dt <= 0) return;
    _angle += _angularVelocity * dt;
    _diskController.value = _angle;
  }

  void _retargetVelocity({required bool animate}) {
    final motion = widget.motionProgress.clamp(0.0, 1.0);
    final target = _isPlaying
        ? (0.9 * _speed * (0.25 + (0.75 * motion)))
        : (0.16 * motion);

    if (!animate) {
      _velocityController.stop();
      final oldListener = _velocityListener;
      if (oldListener != null) {
        _velocityController.removeListener(oldListener);
        _velocityListener = null;
      }
      _angularVelocity = target;
      return;
    }

    _velocityController.stop();
    final oldListener = _velocityListener;
    if (oldListener != null) {
      _velocityController.removeListener(oldListener);
    }
    final from = _angularVelocity;
    final tween = Tween<double>(begin: from, end: target).chain(
      CurveTween(
        curve: _isPlaying ? Curves.easeOutCubic : Curves.easeInCubic,
      ),
    );
    void listener() {
      _angularVelocity = tween.evaluate(_velocityController);
    }
    _velocityListener = listener;
    _velocityController
      ..value = 0.0
      ..addListener(listener)
      ..forward().whenCompleteOrCancel(() {
        if (_velocityListener == listener) {
          _velocityController.removeListener(listener);
          _velocityListener = null;
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _diskController,
          child: _buildDisk(),
          builder: (_, child) {
            return Transform.rotate(angle: _diskController.value, child: child);
          },
        ),
        if (widget.showNeedle)
          Positioned(
            top: -widget.size * 0.12,
            right: -widget.size * 0.15,
            child: VinylNeedle(animation: _needleAnimation, size: widget.size),
          ),
      ],
    );
  }

  Widget _buildDisk() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
        ),
        CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _VinylGroovesPainter(),
        ),
        Container(
          width: widget.size * 0.45,
          height: widget.size * 0.45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade800,
          ),
          child: ClipOval(child: RepaintBoundary(child: _buildCenterArtwork())),
        ),
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              radius: 0.8,
              center: const Alignment(-0.4, -0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterArtwork() {
    final provider = ArtworkCache.provider(widget.artwork);
    if (provider != null) {
      return Image(
        image: provider,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _defaultCenterFallback(),
      );
    }

    if (!kIsWeb && widget.audioId != null) {
      return QueryArtworkWidget(
        id: widget.audioId!,
        type: ArtworkType.AUDIO,
        artworkFit: BoxFit.cover,
        nullArtworkWidget: _defaultCenterFallback(),
      );
    }

    return _defaultCenterFallback();
  }

  Widget _defaultCenterFallback() {
    return Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      child: const Icon(Icons.music_note, color: Colors.white70),
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.05);

    for (double r = size.width * 0.25; r < size.width * 0.5; r += 2.5) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
