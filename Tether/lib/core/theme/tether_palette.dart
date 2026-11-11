import 'package:flutter/material.dart';
import 'tether_tokens.dart';

/// Light and dark color palette for Tether.
/// Access via `context.tether` extension method.
class TetherPalette {
  final Color accent;
  final Color onAccent;
  final Color ground;
  final Color onGround;
  final Color sheet;
  final Color tile;
  final Color card;
  final Color raised;
  final Color border;
  final Color dashed;
  final Color muted;
  final Color mutedOnGround;
  final Color soft;

  const TetherPalette({
    required this.accent,
    required this.onAccent,
    required this.ground,
    required this.onGround,
    required this.sheet,
    required this.tile,
    required this.card,
    required this.raised,
    required this.border,
    required this.dashed,
    required this.muted,
    required this.mutedOnGround,
    required this.soft,
  });

  /// Create light mode palette with gym accent
  factory TetherPalette.light([Color? gymAccent]) {
    final accent = gymAccent ?? TetherTokens.defaultAccent;
    return TetherPalette(
      accent: accent,
      onAccent: _contrastText(accent),
      ground: TetherTokens.cream,
      onGround: TetherTokens.ink,
      sheet: TetherTokens.white,
      tile: TetherTokens.cream,
      card: TetherTokens.white,
      raised: TetherTokens.sand,
      border: TetherTokens.dayBorder,
      dashed: TetherTokens.dayDashed,
      muted: TetherTokens.dayMuted,
      mutedOnGround: TetherTokens.dayMuted,
      soft: TetherTokens.dayMuted,
    );
  }

  /// Create dark mode palette with gym accent
  factory TetherPalette.dark([Color? gymAccent]) {
    final accent = gymAccent ?? TetherTokens.defaultAccent;
    return TetherPalette(
      accent: accent,
      onAccent: _contrastText(accent),
      ground: TetherTokens.night,
      onGround: TetherTokens.cream,
      sheet: TetherTokens.cream,
      tile: TetherTokens.white,
      card: TetherTokens.nightCard,
      raised: TetherTokens.nightRaised,
      border: TetherTokens.nightBorder,
      dashed: TetherTokens.nightDashed,
      muted: TetherTokens.nightMuted,
      mutedOnGround: TetherTokens.nightSoft,
      soft: TetherTokens.nightSoft,
    );
  }

  /// Choose cream or ink text based on accent luminance for WCAG contrast
  static Color _contrastText(Color accent) {
    final luminance = accent.computeLuminance();
    return luminance > 0.5 ? TetherTokens.ink : TetherTokens.cream;
  }
}

/// Extension to access palette from BuildContext
extension TetherPaletteContext on BuildContext {
  TetherPalette get tether {
    final brightness = Theme.of(this).brightness;
    final gymAccent = TetherTokens.defaultAccent; // TODO: Get from gym branding provider
    return brightness == Brightness.light
        ? TetherPalette.light(gymAccent)
        : TetherPalette.dark(gymAccent);
  }
}
