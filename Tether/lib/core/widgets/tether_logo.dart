import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Tether mark from the marketing site, with an optional wordmark.
class TetherLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const TetherLogo({super.key, this.size = 28, this.showWordmark = true});

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size.square(size),
      painter: _TetherMarkPainter(),
    );
    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.36),
        Text(
          'TETHER',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                fontSize: size * 0.58,
              ),
        ),
      ],
    );
  }
}

class _TetherMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on the SVG's 32×32 grid.
    canvas.scale(size.width / 32, size.height / 32);
    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final hook = Path()
      ..moveTo(4, 5)
      ..lineTo(17, 5)
      ..arcToPoint(const Offset(17, 19), radius: const Radius.circular(7))
      ..lineTo(15, 19);
    canvas.drawPath(hook, stroke(AppTheme.onSurface));

    final tee = Path()
      ..moveTo(28, 5)
      ..lineTo(17, 5)
      ..moveTo(22, 5)
      ..lineTo(22, 13)
      ..arcToPoint(const Offset(13, 22), radius: const Radius.circular(9))
      ..arcToPoint(
        const Offset(19, 28),
        radius: const Radius.circular(6),
        clockwise: false,
      )
      ..lineTo(22, 28);
    canvas.drawPath(tee, stroke(AppTheme.primaryContainer));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
