import 'package:flutter/material.dart';

class PlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final Color? color;

  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    this.color,
  });

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didUpdateWidget(covariant PlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔥 SINCRONIZA COM O ESTADO REAL
    if (widget.isPlaying) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _controller,
        size: 56,
        color: widget.color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

