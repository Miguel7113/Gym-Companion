import 'package:flutter/material.dart';
import '../../theme/tether_palette.dart';
import '../../theme/tether_text.dart';
import '../../theme/tether_tokens.dart';

/// Section header label with optional trailing text.
/// Uses uppercase 11pt tracking for visual hierarchy.
class SectionLabel extends StatelessWidget {
  final String text;
  final String? trailing;

  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = context.tether;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text.toUpperCase(),
          style: TetherText.sectionLabel(TetherTokens.ink.withOpacity(0.5)),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TetherText.bodySmall(TetherTokens.ink.withOpacity(0.5)),
          ),
      ],
    );
  }
}
