import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/tether_palette.dart';

/// The iconic Tether ring graphic with optional progress fill.
/// Shown on home screen next to "start a streak" headline.
class TetherRing extends StatelessWidget {
  final double size;
  final double progress; // 0.0 to 1.0

  const TetherRing({
    super.key,
    this.size = 190,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.tether;

    return CustomPaint(
      size: Size(size, size),
      painter: _TetherRingPainter(
        accentColor: p.accent,
        backgroundColor: p.border,
        progress: progress,
      ),
    );
  }
}

class _TetherRingPainter extends CustomPainter {
  final Color accentColor;
  final Color backgroundColor;
  final double progress;

  _TetherRingPainter({
    required this.accentColor,
    required this.backgroundColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.12;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc (if progress > 0)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = accentColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      const startAngle = -math.pi / 2; // Start from top

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TetherRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
