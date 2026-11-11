import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/tether_palette.dart';
import '../../theme/tether_tokens.dart';

/// An animated weight plate that visualizes workout streak progress.
/// The rim has one tick per day of capacity; completed days light up in orange.
/// A soft highlight sweeps around the rim. Respects "reduce motion" setting.
///
/// Fills its parent - give it a box around 190 x 170.
class StreakPlate extends StatefulWidget {
  const StreakPlate({
    super.key,
    required this.streak,
    this.capacity = 14,
  });

  final int streak;
  final int capacity;

  @override
  State<StreakPlate> createState() => _StreakPlateState();
}

class _StreakPlateState extends State<StreakPlate>
    with TickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _sweep.stop();
      _intro.value = 1;
    } else {
      if (!_sweep.isAnimating) _sweep.repeat();
      if (_intro.status == AnimationStatus.dismissed) _intro.forward();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.tether.accent;
    final lit = widget.streak.clamp(0, widget.capacity).toInt();
    
    return Semantics(
      label: '${widget.streak} day streak',
      child: ExcludeSemantics(
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: _PlatePainter(
                    accent,
                    lit,
                    widget.capacity,
                    _sweep,
                    _intro,
                  ),
                ),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        TetherTokens.ink,
                        Color(0x00131211),
                      ],
                      stops: [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  _PlatePainter(
    this.accent,
    this.lit,
    this.capacity,
    this.sweep,
    this.intro,
  ) : super(repaint: Listenable.merge([sweep, intro]));

  final Color accent;
  final int lit, capacity;
  final Animation<double> sweep, intro;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.62, size.height * 0.52);
    final r = size.shortestSide * 0.50;

    // Main disk with gradient
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [
            Color(0xFF34302C),
            Color(0xFF1B1917),
            Color(0xFF0E0D0C),
          ],
          stops: [0, 0.65, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Rim band and edge highlight
    canvas.drawCircle(
      c,
      r * 0.90,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.2
        ..color = const Color(0x66000000),
    );
    canvas.drawCircle(
      c,
      r - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0x1AFFFFFF),
    );

    // Grooves and inner dish
    for (final f in [0.74, 0.66]) {
      canvas.drawCircle(
        c,
        r * f,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0x14FFFFFF),
      );
    }
    canvas.drawCircle(
      c,
      r * 0.52,
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawCircle(
      c,
      r * 0.52,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x1FFFFFFF),
    );

    // Streak ticks - animate in with intro controller
    final litF = lit * Curves.easeOutCubic.transform(intro.value);
    final tickW = math.max(2.5, r * 0.045);
    
    for (var i = 0; i < capacity; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / capacity;
      final dir = Offset(math.cos(a), math.sin(a));
      final p1 = c + dir * (r * 0.84);
      final p2 = c + dir * (r * 0.97);
      final amount = (litF - i).clamp(0.0, 1.0).toDouble();
      
      // Glow for lit ticks
      if (amount > 0) {
        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..strokeWidth = tickW * 1.8
            ..strokeCap = StrokeCap.round
            ..color = accent.withAlpha((150 * amount).round())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      
      // Main tick
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeWidth = tickW
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(
            const Color(0xFF3A3632),
            accent,
            amount,
          )!,
      );
    }

    // Slow highlight sweeping around the rim
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(sweep.value * 2 * math.pi);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.9),
      0,
      0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.18
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: 0.9,
          colors: [
            Color(0x00FFFFFF),
            Color(0x26FFFFFF),
            Color(0x00FFFFFF),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    canvas.restore();

    // Hub - lights up with streak
    canvas.drawCircle(
      c,
      r * 0.2,
      Paint()..color = const Color(0xFF0A0908),
    );
    
    final hubColor = lit > 0 ? accent : const Color(0xFF3A3632);
    
    if (lit > 0) {
      canvas.drawCircle(
        c,
        r * 0.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = accent.withAlpha(120)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    
    canvas.drawCircle(
      c,
      r * 0.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = hubColor,
    );
    canvas.drawCircle(
      c,
      r * 0.045,
      Paint()..color = hubColor,
    );
  }

  @override
  bool shouldRepaint(_PlatePainter old) =>
      old.accent != accent || old.lit != lit || old.capacity != capacity;
}
