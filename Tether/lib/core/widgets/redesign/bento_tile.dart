import 'package:flutter/material.dart';
import '../../theme/tether_tokens.dart';

/// Colored card for bento grid layout on home screen.
/// Can be dark feature cards (always ink) or accent-colored.
class BentoTile extends StatelessWidget {
  final Color color;
  final double height;
  final Widget child;
  final VoidCallback? onTap;

  const BentoTile({
    super.key,
    required this.color,
    required this.height,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(TetherTokens.rCard),
        ),
        child: child,
      ),
    );
  }
}
