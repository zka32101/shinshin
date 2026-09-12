import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_colors.dart';

/// Light theme definition for the app
ThemeData lightTheme() {
  final colorScheme = ThemeColors.lightColorScheme;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.light,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: GoogleFonts.notoSansJp(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Bottom Navigation Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 1,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: GoogleFonts.notoSansJp(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: colorScheme.onBackground,
      ),
      displayMedium: GoogleFonts.notoSansJp(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: colorScheme.onBackground,
      ),
      displaySmall: GoogleFonts.notoSansJp(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      headlineMedium: GoogleFonts.notoSansJp(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      headlineSmall: GoogleFonts.notoSansJp(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      titleLarge: GoogleFonts.notoSansJp(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      bodyLarge: GoogleFonts.notoSansJp(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onBackground,
      ),
      bodyMedium: GoogleFonts.notoSansJp(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onBackground,
      ),
      bodySmall: GoogleFonts.notoSansJp(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.notoSansJp(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.primary,
      ),
    ),
  );
}

/// Dark theme definition for the app
ThemeData darkTheme() {
  final colorScheme = ThemeColors.darkColorScheme;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.dark,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: GoogleFonts.notoSansJp(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Bottom Navigation Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 1,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: GoogleFonts.notoSansJp(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: colorScheme.onBackground,
      ),
      displayMedium: GoogleFonts.notoSansJp(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: colorScheme.onBackground,
      ),
      displaySmall: GoogleFonts.notoSansJp(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      headlineMedium: GoogleFonts.notoSansJp(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      headlineSmall: GoogleFonts.notoSansJp(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      titleLarge: GoogleFonts.notoSansJp(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      bodyLarge: GoogleFonts.notoSansJp(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onBackground,
      ),
      bodyMedium: GoogleFonts.notoSansJp(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onBackground,
      ),
      bodySmall: GoogleFonts.notoSansJp(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.notoSansJp(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.primary,
      ),
    ),
  );
}
