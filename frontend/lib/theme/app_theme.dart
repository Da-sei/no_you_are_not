import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  // ── Colors ──────────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFFF2020);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF777777);
  static const Color border = Color(0xFF2D2D2D);

  // ── Text Styles ──────────────────────────────────────────────────────────────
  static TextStyle get display => GoogleFonts.bebasNeue(
        fontSize: 44,
        color: textPrimary,
        letterSpacing: 5,
        height: 1.0,
      );

  static TextStyle get heading => GoogleFonts.bebasNeue(
        fontSize: 22,
        color: textPrimary,
        letterSpacing: 3,
        height: 1.2,
      );

  static TextStyle get label => GoogleFonts.bebasNeue(
        fontSize: 11,
        color: textSecondary,
        letterSpacing: 3,
      );

  static TextStyle get body => GoogleFonts.ibmPlexMono(
        fontSize: 14,
        color: textPrimary,
        height: 1.6,
      );

  static TextStyle get caption => GoogleFonts.ibmPlexMono(
        fontSize: 12,
        color: textSecondary,
        height: 1.5,
      );

  // ── ThemeData ────────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: accent,
          onPrimary: Colors.white,
          secondary: accent,
          onSecondary: Colors.white,
          onSurface: textPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 20,
          titleTextStyle: GoogleFonts.bebasNeue(
            fontSize: 20,
            color: textPrimary,
            letterSpacing: 4,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.all(16),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: accent),
          ),
          hintStyle: GoogleFonts.ibmPlexMono(
            fontSize: 13,
            color: const Color(0xFF444444),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: border),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surface,
          contentTextStyle: GoogleFonts.ibmPlexMono(
            fontSize: 13,
            color: textPrimary,
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
