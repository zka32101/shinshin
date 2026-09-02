import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum ThemeMode {
  system, // Follow system preference
  light,  // Force light theme
  dark,   // Force dark theme
}

/// Provider for current theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  // Default to system
  return ThemeMode.system;
});

/// Provider for saved theme preference
final savedThemeModeProvider = FutureProvider<ThemeMode>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme_mode') ?? 'system';
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == themeName,
      orElse: () => ThemeMode.system,
    );
  } catch (_) {
    return ThemeMode.system;
  }
});

/// Provider to get brightness based on theme mode and system preference
final brightnessProvider = Provider<Brightness>((ref) {
  final themeMode = ref.watch(themeModeProvider);

  // Determine brightness based on theme mode
  return switch (themeMode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => Brightness.light, // Default to light; actual system preference is handled by MaterialApp
  };
});

/// Provider for setting theme mode and saving preference
final setThemeModeProvider = Provider((ref) {
  return (ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode.name);
      ref.read(themeModeProvider.notifier).state = mode;
    } catch (_) {
      // Silently fail if SharedPreferences is unavailable
    }
  };
});

/// Initialize theme from saved preferences
final initializeThemeProvider = FutureProvider((ref) async {
  final savedMode = await ref.watch(savedThemeModeProvider.future);
  ref.read(themeModeProvider.notifier).state = savedMode;
});
