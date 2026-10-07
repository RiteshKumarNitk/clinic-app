import 'package:flutter/material.dart';

/// CityCare design tokens. Every colour, gradient, radius and type style in
/// the app comes from here — screens never invent their own.
///
/// Palette: blue + aqua + mint, with lime used sparingly as an accent.
/// Text and buttons use the deeper blues so contrast stays readable; the
/// light blue / aqua are for large surfaces and decoration.
class CityCareColors {
  CityCareColors._();

  // Brand
  static const primary = Color(0xFF2F7FB8); // interactive blue (AA on white)
  static const primaryDark = Color(0xFF1F6396);
  static const primaryLight = Color(0xFF65A9D8);
  static const healthBlue = Color(0xFF3B9BD6);
  static const primarySoft = Color(0xFFE6F2FA);
  static const aqua = Color(0xFF52D6D2);
  static const mint = Color(0xFFB8F2D0);
  static const lime = Color(0xFFE8FF6A);
  static const navy = Color(0xFF12324A);

  /// Secondary accent (doctors, info badges): a deep aqua that stays legible.
  static const accent = Color(0xFF178A86);
  static const accentSoft = Color(0xFFE2F8F6);

  // Text
  static const ink = Color(0xFF17364A);
  static const inkMuted = Color(0xFF5E7787);
  static const inkFaint = Color(0xFF8FA4B1);

  // Surfaces
  static const background = Color(0xFFF4FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDDEAF0);
  static const skeleton = Color(0xFFE6F0F5);

  // Status (soft = background, base = icon/text)
  static const success = Color(0xFF1F9A70);
  static const successSoft = Color(0xFFE3F6EE);
  static const warning = Color(0xFF9A6A00);
  static const warningSoft = Color(0xFFFDF3DA);
  static const danger = Color(0xFFD2464B);
  static const dangerSoft = Color(0xFFFCE9EA);
}

class CityCareGradients {
  CityCareGradients._();

  /// Blue → aqua hero surfaces. White text sits on the deeper top-left end.
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F7FB8), Color(0xFF4A9BD3), Color(0xFF52C4D2)],
    stops: [0, 0.6, 1],
  );

  /// Primary buttons: stays dark enough for white text end to end.
  static const button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2A74AB), Color(0xFF2F8FC4)],
  );

  /// Soft page wash behind content.
  static const soft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF8FC), Color(0xFFF4FAFC)],
  );

  /// Lime → mint, for small highlights only.
  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [CityCareColors.lime, CityCareColors.mint],
  );
}

/// Soft, diffuse elevation — never heavy Material shadows.
class CityCareShadows {
  CityCareShadows._();

  static const soft = [
    BoxShadow(color: Color(0x1212324A), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const lifted = [
    BoxShadow(color: Color(0x2212324A), blurRadius: 36, offset: Offset(0, 16)),
  ];

  static const glow = [
    BoxShadow(color: Color(0x402F7FB8), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

class CityCareSpacing {
  CityCareSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Screen side gutter.
  static const gutter = 20.0;
}

class CityCareRadius {
  CityCareRadius._();

  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

const _font = 'Poppins';

ThemeData buildClinicTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CityCareColors.primary,
    primary: CityCareColors.primary,
    secondary: CityCareColors.accent,
    tertiary: CityCareColors.lime,
    surface: CityCareColors.surface,
    error: CityCareColors.danger,
  );

  const text = TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.12,
      letterSpacing: -1.0,
      color: CityCareColors.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.6,
      color: CityCareColors.ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.3,
      color: CityCareColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: CityCareColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: CityCareColors.ink,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: CityCareColors.ink,
    ),
    bodyLarge: TextStyle(
      fontSize: 15.5,
      height: 1.5,
      color: CityCareColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.5,
      color: CityCareColors.inkMuted,
    ),
    bodySmall: TextStyle(
      fontSize: 12.5,
      height: 1.45,
      color: CityCareColors.inkMuted,
    ),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  final pill = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(CityCareRadius.pill),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: _font,
    colorScheme: scheme,
    scaffoldBackgroundColor: CityCareColors.background,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: CityCareColors.background,
      foregroundColor: CityCareColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: _font,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: CityCareColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: CityCareColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CityCareRadius.lg),
        side: const BorderSide(color: CityCareColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CityCareColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: CityCareColors.border,
        disabledForegroundColor: CityCareColors.inkFaint,
        minimumSize: const Size.fromHeight(54),
        shape: pill,
        textStyle: text.labelLarge?.copyWith(fontFamily: _font),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CityCareColors.primary,
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: CityCareColors.primary, width: 1.3),
        shape: pill,
        textStyle: text.labelLarge?.copyWith(fontFamily: _font),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CityCareColors.primary,
        textStyle: text.labelLarge?.copyWith(fontFamily: _font),
        minimumSize: const Size(48, 44),
        shape: pill,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CityCareColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: const TextStyle(color: CityCareColors.inkFaint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CityCareRadius.md),
        borderSide: const BorderSide(color: CityCareColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CityCareRadius.md),
        borderSide: const BorderSide(color: CityCareColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CityCareRadius.md),
        borderSide: const BorderSide(color: CityCareColors.primary, width: 1.6),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CityCareColors.surface,
      selectedColor: CityCareColors.primarySoft,
      side: const BorderSide(color: CityCareColors.border),
      labelStyle: const TextStyle(
        fontFamily: _font,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: CityCareColors.ink,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: CityCareColors.surface,
        selectedBackgroundColor: CityCareColors.primarySoft,
        selectedForegroundColor: CityCareColors.primaryDark,
        foregroundColor: CityCareColors.inkMuted,
        side: const BorderSide(color: CityCareColors.border),
        textStyle: const TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: CityCareColors.primaryDark,
      unselectedLabelColor: CityCareColors.inkMuted,
      indicatorColor: CityCareColors.primary,
      labelStyle: TextStyle(fontFamily: _font, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w500,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CityCareColors.surface,
      indicatorColor: CityCareColors.primarySoft,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: _font,
          fontSize: 11.5,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? CityCareColors.primaryDark
              : CityCareColors.inkMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? CityCareColors.primaryDark
              : CityCareColors.inkMuted,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: CityCareColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CityCareRadius.xl),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: CityCareColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: CityCareColors.border,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: CityCareColors.navy,
      contentTextStyle: const TextStyle(fontFamily: _font, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CityCareRadius.md),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: CityCareColors.primary,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
