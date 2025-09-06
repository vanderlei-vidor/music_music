import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';

class WaveformPainter extends CustomPainter {
  final Waveform waveform;
  final double progress; // 0.0 a 1.0
  final Color playedColor;
  final Color unplayedColor;
  final double strokeWidth;

  WaveformPainter({
    required this.waveform,
    required this.progress,
    this.playedColor = Colors.white,
    this.unplayedColor = Colors.white24,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.data.isEmpty) return;

    final playedPaint = Paint()
      ..color = playedColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final unplayedPaint = Paint()
      ..color = unplayedColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double widthPerSample = size.width / waveform.data.length;
    final int playedSamplesCount = (waveform.data.length * progress).toInt();

    for (int i = 0; i < waveform.data.length; i++) {
      final sample = waveform.data[i];

      

      final x = i * widthPerSample;
      final normalizedY = (sample / 128.0) * (size.height / 2);

      final paint = i < playedSamplesCount ? playedPaint : unplayedPaint;

      canvas.drawLine(
    Offset(x, size.height / 2 - normalizedY),
    Offset(x, size.height / 2 + normalizedY),
    paint,
    );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveform != waveform;
  }
}
