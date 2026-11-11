import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tether_tokens.dart';

/// Typography system for Tether redesign.
/// Uses Bricolage Grotesque (sans) and Instrument Serif (italic highlights).
class TetherText {
  TetherText._();

  /// Sans-serif text (Bricolage Grotesque)
  static TextStyle sans(
    double size, {
    FontWeight? w,
    Color? color,
    double? height,
    double? ls, // letter spacing in pts (not %)
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: w ?? TetherTokens.w400,
      color: color,
      height: height, // Don't divide! height is already a multiplier
      letterSpacing: ls,
    );
  }

  /// Serif italic text for highlighted words (Instrument Serif)
  static TextStyle serif(double size, Color color, {double? height, double? ls}) {
    return GoogleFonts.instrumentSerif(
      fontSize: size,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: color,
      height: height, // Don't divide! height is already a multiplier
      letterSpacing: ls,
    );
  }

  /// Heavy numerals (Bricolage Grotesque 800)
  static TextStyle numeral(double size, Color color, {double? height, double? ls}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: TetherTokens.w800,
      color: color,
      height: height, // Don't divide! height is already a multiplier
      letterSpacing: ls,
    );
  }

  /// Uppercase labels with increased tracking
  static TextStyle label(
    double size,
    Color color, {
    FontWeight? w,
    double? ls,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: w ?? TetherTokens.w600,
      color: color,
      letterSpacing: ls ?? size * 0.06, // Default 6% tracking
    );
  }

  // Common text styles for quick access
  static TextStyle screenTitle(Color color, [Color? accentColor]) {
    return sans(40, w: TetherTokens.w800, color: color, height: 1.02, ls: -0.8);
  }

  static TextStyle screenTitleAccent(Color accentColor) {
    // Use sans-serif for better reliability, slightly lighter weight for contrast
    return sans(40, w: TetherTokens.w600, color: accentColor, height: 1.02, ls: -0.8);
  }

  static TextStyle sectionLabel(Color color) {
    return label(11, color, w: TetherTokens.w800, ls: 0.88);
  }

  static TextStyle cardTitle(Color color) {
    return sans(18, w: TetherTokens.w600, color: color, height: 1.28, ls: -0.36);
  }

  static TextStyle tileTitle(Color color) {
    return sans(16, w: TetherTokens.w600, color: color, ls: -0.32);
  }

  static TextStyle body(Color color) {
    return sans(14, w: TetherTokens.w400, color: color, height: 1.42);
  }

  static TextStyle bodySmall(Color color) {
    return sans(13, w: TetherTokens.w400, color: color, height: 1.38);
  }

  static TextStyle caption(Color color) {
    return sans(12, w: TetherTokens.w400, color: color);
  }
}
