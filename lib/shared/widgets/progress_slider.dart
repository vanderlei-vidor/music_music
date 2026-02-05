import 'package:flutter/material.dart';

class ProgressSlider extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const ProgressSlider({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider> {
  double? _dragValue;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final max = widget.duration.inMilliseconds.toDouble();
    final value = _dragValue ??
        widget.position.inMilliseconds.clamp(0, max).toDouble();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: _PremiumThumb(
              radius: _isDragging ? 10 : 7,
            ),
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor:
                theme.colorScheme.onSurface.withOpacity(0.25),
          ),
          child: Slider(
            min: 0,
            max: max > 0 ? max : 1,
            value: value,
            onChangeStart: (_) {
              setState(() => _isDragging = true);
            },
            onChanged: (v) {
              setState(() => _dragValue = v);
            },
            onChangeEnd: (v) {
              setState(() {
                _isDragging = false;
                _dragValue = null;
              });
              widget.onSeek(
                Duration(milliseconds: v.toInt()),
              );
            },
          ),
        ),

        // ⏱️ TEMPOS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _time(widget.position),
              _time(widget.duration),
            ],
          ),
        ),
      ],
    );
  }

  Widget _time(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return Text('$minutes:$seconds');
  }
}

class _PremiumThumb extends SliderComponentShape {
  final double radius;

  const _PremiumThumb({required this.radius});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final paint = Paint()
      ..color = sliderTheme.activeTrackColor!
      ..style = PaintingStyle.fill;

    context.canvas.drawCircle(center, radius, paint);
  }
}

