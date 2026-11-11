import 'package:flutter/material.dart';
import '../../theme/tether_palette.dart';
import '../../theme/tether_tokens.dart';

/// Layout with header on ground color and rounded sheet rising over it.
/// This is the signature Tether layout pattern.
class HeaderSheetLayout extends StatelessWidget {
  final Widget header;
  final List<Widget> children;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? sheetPadding;

  const HeaderSheetLayout({
    super.key,
    required this.header,
    required this.children,
    this.headerPadding,
    this.sheetPadding,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.tether;

    return CustomScrollView(
      slivers: [
        // Header section with ground color
        SliverToBoxAdapter(
          child: Container(
            color: p.ground,
            padding: headerPadding ??
                const EdgeInsets.fromLTRB(
                  TetherTokens.screenPad,
                  60, // Top safe area + status bar
                  TetherTokens.screenPad,
                  32,
                ),
            child: header,
          ),
        ),

        // Sheet section with rounded top
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: p.sheet,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(TetherTokens.rSheet),
              ),
            ),
            padding: sheetPadding ??
                const EdgeInsets.symmetric(
                  horizontal: TetherTokens.screenPad,
                  vertical: 24,
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),

        // Bottom padding for nav bar
        const SliverToBoxAdapter(
          child: SizedBox(height: TetherTokens.navHeight + TetherTokens.navBottomMargin + 20),
        ),
      ],
    );
  }
}
