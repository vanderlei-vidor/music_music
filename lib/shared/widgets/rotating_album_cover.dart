import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class RotatingAlbumCover extends StatefulWidget {
  final String? artwork;
  final AudioPlayer player;
  final double size;

  const RotatingAlbumCover({
    super.key,
    required this.artwork,
    required this.player,
    this.size = 180,
  });

  @override
  State<RotatingAlbumCover> createState() => _RotatingAlbumCoverState();
}

class _RotatingAlbumCoverState extends State<RotatingAlbumCover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    widget.player.playingStream.listen((isPlaying) {
      if (isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: widget.artwork != null
                ? DecorationImage(
                    image: NetworkImage(widget.artwork!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.black38,
          ),
          child: widget.artwork == null
              ? const Icon(Icons.album, size: 80, color: Colors.white70)
              : null,
        ),
      ),
    );
  }
}
