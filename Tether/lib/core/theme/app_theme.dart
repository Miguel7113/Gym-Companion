import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Color Palette ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFF283500);
  static const Color primaryContainer = Color(0xFFC3F400); // Neon lime — the ONE accent
  static const Color onPrimaryContainer = Color(0xFF556D00);
  static const Color primaryFixedDim = Color(0xFFABD600); // Pressed/active lime
  static const Color onPrimaryFixed = Color(0xFF161E00); // Text on lime buttons

  static const Color secondary = Color(0xFFC8C6C5);
  static const Color onSecondary = Color(0xFF313030);
  static const Color secondaryContainer = Color(0xFF4A4949);
  static const Color onSecondaryContainer = Color(0xFFBAB8B7);

  static const Color tertiary = Color(0xFFFFFFFF);
  static const Color onTertiary = Color(0xFF313030);
  static const Color tertiaryContainer = Color(0xFFE5E2E1);
  static const Color onTertiaryContainer = Color(0xFF656464);

  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Surface hierarchy — deepest to brightest
  static const Color surfaceContainerLowest = Color(0xFF0D0E12);
  static const Color surface = Color(0xFF121317); // Base background
  static const Color surfaceContainerLow = Color(0xFF1A1B1F);
  static const Color surfaceContainer = Color(0xFF1E1F23);
  static const Color surfaceContainerHigh = Color(0xFF292A2E);
  static const Color surfaceContainerHighest = Color(0xFF343539);
  static const Color surfaceBright = Color(0xFF38393D);

  static const Color onSurface = Color(0xFFE3E2E7);
  static const Color onSurfaceVariant = Color(0xFFC4C9AC);
  static const Color outline = Color(0xFF8E9379);
  static const Color outlineVariant = Color(0xFF444933);
  static const Color inverseSurface = Color(0xFFE3E2E7);
  static const Color onInverseSurface = Color(0xFF2F3034);
  static const Color inversePrimary = Color(0xFF506600);

  // ─── Spacing Scale (8px base unit) ────────────────────────────────────────
  static const double unit = 8.0;
  static const double stackSm = 12.0;
  static const double gutter = 16.0;
  static const double stackMd = 24.0;
  static const double containerMargin = 20.0;
  static const double stackLg = 40.0;

  // ─── Border Radius ────────────────────────────────────────────────────────
  // Matches design system: cards=xl(12), buttons/tags=full(pill), badges=lg(8)
  static const double radiusSm = 4.0;   // DEFAULT in design tokens
  static const double radiusLg = 8.0;   // lg — icon badges, small elements
  static const double radiusXl = 12.0;  // xl — cards, modals (primary container shape)
  static const double radiusXxl = 16.0; // extra — section panels, glass panels
  static const double radiusFull = 9999.0; // pill — buttons, tags, chips

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

      // System UI overlay — transparent status bar, dark icons not needed on dark bg
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

      // Cards use xl radius (12px), no elevation — depth via tonal fill
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        margin: EdgeInsets.zero,
      ),

      // Primary CTA: solid lime, pill-shaped, neon glow via BoxShadow
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
          textStyle: GoogleFonts.oswald(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
          ),
        ),
      ),

      // Outlined secondary: glass style
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
        ),
      ),

      // Text buttons: lime label
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryContainer,
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Input fields: ghost style — bottom border only, lime on focus
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

      // Chips: pill shaped, label-caps font
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHigh,
        selectedColor: primaryContainer.withOpacity(0.15),
        secondarySelectedColor: primaryContainer.withOpacity(0.15),
        labelStyle: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        secondaryLabelStyle: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: primaryContainer,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF),
        thickness: 1,
        space: 0,
      ),

      // BottomNav is handled manually (glassmorphism), hide the default
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // Icons: use outlined weight 300 by default; screens set FILL=1 for active
      iconTheme: const IconThemeData(
        color: onSurfaceVariant,
        size: 24,
      ),

      textTheme: _buildTextTheme(),
    );
  }

  // ─── Typography ───────────────────────────────────────────────────────────
  // Three-font system:
  //   Oswald     → anything heroic/bold (headlines, stats, buttons)
  //   Inter      → comfortable reading (body, captions)
  //   JetBrains Mono → all metadata (timestamps, labels, metric tags) — always uppercase
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // display-lg: 48/56 — hero stats ("52 MIN", PRs)
      displayLarge: GoogleFonts.oswald(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 56 / 48,
        letterSpacing: -0.02 * 48,
        color: onSurface,
      ),
      // stat-lg: 36/44 — secondary stats in bento grid
      displayMedium: GoogleFonts.oswald(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 44 / 36,
        color: onSurface,
      ),
      // headline-lg: 32/40 — screen titles on desktop
      displaySmall: GoogleFonts.oswald(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        letterSpacing: 0.01 * 32,
        color: onSurface,
      ),
      // headline-lg-mobile: 28/34 — screen titles on mobile
      headlineLarge: GoogleFonts.oswald(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 34 / 28,
        color: onSurface,
      ),
      // headline-md: 24/32 — section headers, button labels
      headlineMedium: GoogleFonts.oswald(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 32 / 24,
        color: onSurface,
      ),
      // Minor headline for sub-sections
      headlineSmall: GoogleFonts.oswald(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 28 / 20,
        color: onSurface,
      ),
      // body-lg: 18/28 — captions, longer social text
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        color: onSurface,
      ),
      // body-md: 16/24 — standard body, post captions
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
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
      // label-caps: 12/16 — ALL metadata. Always render uppercase.
      labelLarge: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 16 / 12,
        letterSpacing: 0.1 * 12,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 14 / 11,
        letterSpacing: 0.1 * 11,
        color: onSurface,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 12 / 10,
        letterSpacing: 0.1 * 10,
        color: onSurfaceVariant,
      ),
    );
  }

  // ─── Reusable Decorations ─────────────────────────────────────────────────

  /// Glassmorphism panel — cards, stat tiles, app bars
  static BoxDecoration glassDecoration({
    double opacity = 0.6,
    double borderRadius = radiusXl,
    Color? color,
  }) {
    return BoxDecoration(
      color: (color ?? surface).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
    );
  }

  /// Neon lime glow — used on primary CTAs, PR badges, active elements
  static List<BoxShadow> neonGlow({double opacity = 0.15, double blur = 20}) {
    return [
      BoxShadow(
        color: primaryContainer.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: 0,
      ),
    ];
  }

  /// Photo scrim — gradient over hero images so Oswald headlines stay legible
  static const LinearGradient photoScrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0xFF121317),       // 100% opaque at bottom
      Color(0xCC121317),       // 80% at lower-mid
      Color(0x4D121317),       // 30% at upper-mid
      Color(0x00121317),       // transparent at top
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  /// Announcement card gradient tint (lime → transparent)
  static const LinearGradient limeAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AC3F400), // lime at 10%
      Colors.transparent,
    ],
  );
}
