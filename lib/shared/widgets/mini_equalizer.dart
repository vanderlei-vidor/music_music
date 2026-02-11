import 'package:flutter/material.dart';

class MiniEqualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double size;

  const MiniEqualizer({
    super.key,
    required this.isPlaying,
    required this.color,
    this.size = 22,
  });

  @override
  State<MiniEqualizer> createState() => _MiniEqualizerState();
}

class _MiniEqualizerState extends State<MiniEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _bars;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bars = List.generate(3, (i) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            i * 0.2,
            1.0,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MiniEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    } else {
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
    return SizedBox(
      height: widget.size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_bars.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedBuilder(
              animation: _bars[i],
              builder: (_, __) {
                return Container(
                  width: 3,
                  height: widget.size * _bars[i].value,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
