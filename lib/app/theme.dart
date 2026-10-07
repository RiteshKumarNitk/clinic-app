import 'package:flutter/material.dart';

/// Clinic App design tokens — a calm, clinical teal identity, deliberately
/// distinct from any other DoseWise product.
class ClinicColors {
  ClinicColors._();

  static const primary = Color(0xFF0E7C7B);
  static const primaryDark = Color(0xFF0A5A59);
  static const primarySoft = Color(0xFFE3F2F1);
  static const accent = Color(0xFF2F6FDE);
  static const accentSoft = Color(0xFFE8F0FD);

  static const ink = Color(0xFF0F1E2E);
  static const inkMuted = Color(0xFF5A6878);
  static const inkFaint = Color(0xFF8A97A5);

  static const background = Color(0xFFF4F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8EE);
  static const skeleton = Color(0xFFE8EDF2);

  static const success = Color(0xFF15803D);
  static const successSoft = Color(0xFFE6F4EA);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFDF1E3);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFDECEA);
}

class ClinicSpacing {
  ClinicSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Screen side gutter.
  static const gutter = 20.0;
}

class ClinicRadius {
  ClinicRadius._();

  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
}

ThemeData buildClinicTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ClinicColors.primary,
    primary: ClinicColors.primary,
    secondary: ClinicColors.accent,
    surface: ClinicColors.surface,
    error: ClinicColors.danger,
  );

  const text = TextTheme(
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.4,
      color: ClinicColors.ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.2,
      color: ClinicColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: ClinicColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: ClinicColors.ink,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: ClinicColors.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: ClinicColors.ink),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.45,
      color: ClinicColors.inkMuted,
    ),
    bodySmall: TextStyle(
      fontSize: 12.5,
      height: 1.4,
      color: ClinicColors.inkMuted,
    ),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  final roundedButton = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(ClinicRadius.md),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: ClinicColors.background,
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: ClinicColors.background,
      foregroundColor: ClinicColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ClinicColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: ClinicColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClinicRadius.lg),
        side: const BorderSide(color: ClinicColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ClinicColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: roundedButton,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ClinicColors.primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: ClinicColors.border, width: 1.2),
        shape: roundedButton,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ClinicColors.primary,
        textStyle: text.labelLarge,
        minimumSize: const Size(48, 44),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ClinicColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: ClinicColors.inkFaint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClinicRadius.md),
        borderSide: const BorderSide(color: ClinicColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClinicRadius.md),
        borderSide: const BorderSide(color: ClinicColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClinicRadius.md),
        borderSide: const BorderSide(color: ClinicColors.primary, width: 1.6),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ClinicColors.surface,
      selectedColor: ClinicColors.primarySoft,
      side: const BorderSide(color: ClinicColors.border),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ClinicColors.ink,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClinicRadius.sm),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ClinicColors.surface,
      indicatorColor: ClinicColors.primarySoft,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? ClinicColors.primaryDark
              : ClinicColors.inkMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? ClinicColors.primaryDark
              : ClinicColors.inkMuted,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: ClinicColors.border,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ClinicColors.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClinicRadius.sm),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
