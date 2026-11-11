import 'package:flutter/material.dart';
import '../../theme/tether_palette.dart';
import '../../theme/tether_text.dart';
import '../../theme/tether_tokens.dart';

enum DayState {
  completed,
  today,
  upcoming,
  off,
}

class DayDot {
  final String label; // M, T, W, etc.
  final DayState state;
  final String? date; // Optional day number for "today"

  const DayDot(this.label, this.state, {this.date});
}

/// Week strip showing 7 days with completion states.
/// Displays Monday-Sunday with dots/indicators for workout status.
class WeekStrip extends StatelessWidget {
  final List<DayDot> days;

  const WeekStrip({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final p = context.tether;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) => _DayIndicator(day: day, palette: p)).toList(),
    );
  }
}

class _DayIndicator extends StatelessWidget {
  final DayDot day;
  final TetherPalette palette;

  const _DayIndicator({required this.day, required this.palette});

  @override
  Widget build(BuildContext context) {
    final isToday = day.state == DayState.today;
    final isCompleted = day.state == DayState.completed;
    final isOff = day.state == DayState.off;

    Color dotColor;
    Color textColor;
    Widget dotWidget;

    if (isCompleted) {
      dotColor = palette.accent;
      textColor = TetherTokens.ink.withOpacity(0.7);
      dotWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: palette.accent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: palette.onAccent,
          size: 20,
        ),
      );
    } else if (isToday) {
      dotColor = palette.accent;
      textColor = TetherTokens.ink.withOpacity(0.7);
      dotWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: palette.accent, width: 2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            day.date ?? '',
            style: TetherText.sans(14, w: TetherTokens.w600, color: palette.accent),
          ),
        ),
      );
    } else if (isOff) {
      dotColor = TetherTokens.ink.withOpacity(0.3);
      textColor = TetherTokens.ink.withOpacity(0.4);
      dotWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: TetherTokens.ink.withOpacity(0.2), width: 2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '—',
            style: TetherText.sans(16, color: TetherTokens.ink.withOpacity(0.3)),
          ),
        ),
      );
    } else {
      // Upcoming - outlined circle
      dotColor = TetherTokens.ink.withOpacity(0.2);
      textColor = TetherTokens.ink.withOpacity(0.5);
      dotWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: TetherTokens.ink.withOpacity(0.2), width: 2),
          shape: BoxShape.circle,
        ),
      );
    }

    return Column(
      children: [
        Text(
          day.label,
          style: TetherText.label(11, textColor),
        ),
        const SizedBox(height: 8),
        dotWidget,
      ],
    );
  }
}
