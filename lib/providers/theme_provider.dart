import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum AppThemeMode {
  system, // Follow system preference
  light,  // Force light theme
  dark,   // Force dark theme
}

/// Provider for current theme mode
final themeModeProvider = StateProvider<AppThemeMode>((ref) {
  // Default to system
  return AppThemeMode.system;
});

/// Provider for saved theme preference
final savedThemeModeProvider = FutureProvider<AppThemeMode>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme_mode') ?? 'system';
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == themeName,
      orElse: () => AppThemeMode.system,
    );
  } catch (_) {
    return AppThemeMode.system;
  }
});

/// Provider to get brightness based on theme mode and system preference
final brightnessProvider = Provider<Brightness>((ref) {
  final themeMode = ref.watch(themeModeProvider);

  // Determine brightness based on theme mode
  return switch (themeMode) {
    AppThemeMode.light => Brightness.light,
    AppThemeMode.dark => Brightness.dark,
    AppThemeMode.system => Brightness.light, // Default to light; actual system preference is handled by MaterialApp
  };
});

/// Provider for setting theme mode and saving preference
final setThemeModeProvider = Provider((ref) {
  return (AppThemeMode mode) async {
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
