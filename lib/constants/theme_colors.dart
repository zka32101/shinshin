import 'package:flutter/material.dart';

/// Theme color definitions for light and dark modes
/// Extends the base AppColors with theme-aware color schemes
class ThemeColors {
  // ════════════════════════════════════════════════════════════════════════════
  // LIGHT THEME COLORS
  // ════════════════════════════════════════════════════════════════════════════

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6366F1),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE0E7FF),
    onPrimaryContainer: Color(0xFF1E1B4B),
    secondary: Color(0xFF8B5CF6),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF3E8FF),
    onSecondaryContainer: Color(0xFF4C1D95),
    tertiary: Color(0xFF06B6D4),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFCFFAFE),
    onTertiaryContainer: Color(0xFF164E63),
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    background: Color(0xFFFAFAFA),
    onBackground: Color(0xFF1F2937),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F2937),
    surfaceVariant: Color(0xFFF3F4F6),
    onSurfaceVariant: Color(0xFF6B7280),
    outline: Color(0xFFD1D5DB),
    outlineVariant: Color(0xFFE5E7EB),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1F2937),
    inverseOnSurface: Color(0xFFF9FAFB),
    inversePrimary: Color(0xFFA5B4FC),
  );

  // ════════════════════════════════════════════════════════════════════════════
  // DARK THEME COLORS
  // ════════════════════════════════════════════════════════════════════════════

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA5B4FC),
    onPrimary: Color(0xFF1E1B4B),
    primaryContainer: Color(0xFF4F46E5),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFFE9D5FF),
    onSecondary: Color(0xFF4C1D95),
    secondaryContainer: Color(0xFF7C3AED),
    onSecondaryContainer: Color(0xFFF3E8FF),
    tertiary: Color(0xFF06B6D4),
    onTertiary: Color(0xFF164E63),
    tertiaryContainer: Color(0xFF0891B2),
    onTertiaryContainer: Color(0xFFCFFAFE),
    error: Color(0xFFFCA5A5),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFFDC2626),
    onErrorContainer: Color(0xFFFEE2E2),
    background: Color(0xFF111827),
    onBackground: Color(0xFFF9FAFB),
    surface: Color(0xFF1F2937),
    onSurface: Color(0xFFF9FAFB),
    surfaceVariant: Color(0xFF374151),
    onSurfaceVariant: Color(0xFFD1D5DB),
    outline: Color(0xFF6B7280),
    outlineVariant: Color(0xFF4B5563),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF9FAFB),
    inverseOnSurface: Color(0xFF1F2937),
    inversePrimary: Color(0xFF6366F1),
  );

  /// Get the appropriate color scheme based on brightness
  static ColorScheme colorSchemeForBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? darkColorScheme : lightColorScheme;
  }
}
