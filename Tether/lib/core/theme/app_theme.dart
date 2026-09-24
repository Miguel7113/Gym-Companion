import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Color Palette ────────────────────────────────────────────────────────
  // Cool cyan/teal accent — used sparingly for CTAs, active states, highlights.
  static const Color primary = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFF04201A);
  static const Color primaryContainer = Color(0xFF2DE2C5); // Cool teal accent
  static const Color onPrimaryContainer = Color(0xFF0A3D36);
  static const Color primaryFixedDim = Color(0xFF1FC4AB); // Pressed/active teal
  static const Color onPrimaryFixed = Color(0xFF04201A); // Text on teal buttons

  static const Color secondary = Color(0xFFC8C6C5);
  static const Color onSecondary = Color(0xFF313030);
  static const Color secondaryContainer = Color(0xFF3A3A3C);
  static const Color onSecondaryContainer = Color(0xFFBAB8B7);

  static const Color tertiary = Color(0xFFFFFFFF);
  static const Color onTertiary = Color(0xFF313030);
  static const Color tertiaryContainer = Color(0xFFE5E2E1);
  static const Color onTertiaryContainer = Color(0xFF656464);

  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Surface hierarchy — pure black stack (WHOOP-inspired)
  static const Color surfaceContainerLowest = Color(0xFF000000);
  static const Color surface = Color(0xFF000000); // Base background
  static const Color surfaceContainerLow = Color(0xFF0A0A0A);
  static const Color surfaceContainer = Color(0xFF141414);
  static const Color surfaceContainerHigh = Color(0xFF1C1C1E);
  static const Color surfaceContainerHighest = Color(0xFF2C2C2E);
  static const Color surfaceBright = Color(0xFF3A3A3C);

  static const Color onSurface = Color(0xFFF5F5F7);
  static const Color onSurfaceVariant = Color(0xFFA1A1A6);
  static const Color outline = Color(0xFF636366);
  static const Color outlineVariant = Color(0xFF3A3A3C);
  static const Color inverseSurface = Color(0xFFF5F5F7);
  static const Color onInverseSurface = Color(0xFF1C1C1E);
  static const Color inversePrimary = Color(0xFF0A7A6A);

  // Semantic metric colors (WHOOP-style)
  static const Color metricGood = Color(0xFF34C759);
  static const Color metricModerate = Color(0xFFFFD60A);
  static const Color metricAttention = Color(0xFFFF453A);

  // Status tones shared with the staff portal (dialogs, snackbars, pills)
  static const Color toneDanger = Color(0xFFFB7185);
  static const Color toneSuccess = Color(0xFF34D399);
  static const Color toneWarning = Color(0xFFFBBF24);
  static const Color hairline = Color(0x12FFFFFF); // 7% white
  static const Color hairlineStrong = Color(0x1FFFFFFF); // 12% white

  // ─── Spacing Scale (8px base unit) ────────────────────────────────────────
  static const double unit = 8.0;
  static const double stackSm = 12.0;
  static const double gutter = 16.0;
  static const double stackMd = 24.0;
  static const double containerMargin = 20.0;
  static const double stackLg = 40.0;

  // ─── Border Radius ────────────────────────────────────────────────────────
  static const double radiusSm = 4.0;
  static const double radiusLg = 8.0;
  static const double radiusXl = 12.0;
  static const double radiusXxl = 16.0;
  static const double radiusFull = 9999.0;

  // ─── ColorScheme (Material 3 dark) ────────────────────────────────────────
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: onInverseSurface,
    inversePrimary: inversePrimary,
  );

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: surface,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryContainer,
          foregroundColor: onPrimaryFixed,
          disabledBackgroundColor: surfaceContainerHigh,
          disabledForegroundColor: onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: onSurface,
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryContainer,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primaryContainer, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: error, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 16,
          color: onSurfaceVariant,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: primaryContainer,
        ),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHigh,
        selectedColor: primaryContainer.withOpacity(0.15),
        secondarySelectedColor: primaryContainer.withOpacity(0.15),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: primaryContainer,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF),
        thickness: 1,
        space: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: hairline),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          height: 1.45,
          color: onSurfaceVariant,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceContainerHigh,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: hairlineStrong),
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        actionTextColor: onSurface,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: surfaceBright,
        dragHandleSize: Size(36, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXxl)),
          side: BorderSide(color: hairline),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      iconTheme: const IconThemeData(
        color: onSurfaceVariant,
        size: 24,
      ),

      textTheme: _buildTextTheme(),
    );
  }

  // ─── Typography ───────────────────────────────────────────────────────────
  // Editorial pairing:
  //   Space Grotesk → headlines, stats, buttons (tight, modern)
  //   Inter         → body, captions, section labels (sentence case)
  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 56 / 48,
        letterSpacing: -1.2,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 44 / 36,
        letterSpacing: -0.8,
        color: onSurface,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 34 / 28,
        letterSpacing: -0.4,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 28 / 18,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
        letterSpacing: -0.1,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        letterSpacing: -0.1,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: onSurfaceVariant,
      ),
      // Section / metadata labels — sentence case, tight tracking
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 16 / 13,
        letterSpacing: -0.1,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 14 / 12,
        letterSpacing: -0.05,
        color: onSurface,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 12 / 11,
        letterSpacing: 0,
        color: onSurfaceVariant,
      ),
    );
  }

  // ─── Reusable Decorations ─────────────────────────────────────────────────

  /// Soft panel — cards, stat tiles, app bars
  static BoxDecoration glassDecoration({
    double opacity = 0.85,
    double borderRadius = radiusXl,
    Color? color,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: (color ?? surfaceContainer).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.08),
        width: 1,
      ),
      boxShadow: elevated ? cardElevation : null,
    );
  }

  /// Soft teal glow — primary CTAs, active elements, PR badges
  static List<BoxShadow> neonGlow({double opacity = 0.18, double blur = 20}) {
    return [
      BoxShadow(
        color: primaryContainer.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: 0,
      ),
    ];
  }

  /// Subtle elevation for interactive cards (Strava/Hevy depth)
  static List<BoxShadow> get cardElevation => [
        BoxShadow(
          color: Colors.black.withOpacity(0.45),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.03),
          blurRadius: 0,
          offset: const Offset(0, -0.5),
        ),
      ];

  /// Photo scrim — gradient over hero images so headlines stay legible
  static const LinearGradient photoScrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0xFF000000),
      Color(0xCC000000),
      Color(0x4D000000),
      Color(0x00000000),
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  /// Accent tint for announcement / highlight cards
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1A2DE2C5),
      Colors.transparent,
    ],
  );

  /// @Deprecated — use [accentGradient]
  static const LinearGradient limeAccentGradient = accentGradient;
}
