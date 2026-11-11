import 'package:flutter/material.dart';

/// Raw design values from the Tether redesign.
/// Screens should use TetherPalette via context.tether instead of these directly.
class TetherTokens {
  TetherTokens._();

  // Default gym accent (ember orange). Gyms can override at runtime.
  static const Color defaultAccent = Color(0xFFFF5A1F);

  // Core colors
  static const Color ink = Color(0xFF14110F);
  static const Color cream = Color(0xFFF4EFE8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color sand = Color(0xFFE4DDD2);

  // Dark mode colors
  static const Color night = Color(0xFF0E0D0C);
  static const Color nightCard = Color(0xFF1A1816);
  static const Color nightRaised = Color(0xFF2A2623);
  static const Color nightBorder = Color(0xFF2E2A27);
  static const Color nightDashed = Color(0xFF4A443F);
  static const Color nightMuted = Color(0xFFA39B90);
  static const Color nightSoft = Color(0xFFCFC8BE);

  // Light mode colors
  static const Color dayMuted = Color(0xFF5E574F);
  static const Color dayBorder = Color(0xFFD8D0C4);
  static const Color dayDashed = Color(0xFFBDB5AA);

  // Radii
  static const double rSheet = 32;
  static const double rCard = 28;
  static const double rTile = 24;
  static const double rExerciseTile = 26;
  static const double rPill = 999; // Fully round

  // Layout
  static const double screenPad = 20;
  static const double navHeight = 68;
  static const double navBottomMargin = 20;
  static const double navSideMargin = 16;
  static const double minTap = 44;

  // Typography weights
  static const FontWeight w400 = FontWeight.w400;
  static const FontWeight w600 = FontWeight.w600;
  static const FontWeight w800 = FontWeight.w800;
}
