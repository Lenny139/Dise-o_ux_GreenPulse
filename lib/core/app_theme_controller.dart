import 'package:flutter/material.dart';

class AppThemeController {
  AppThemeController._();

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );

  static void applyThemeLabel(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('oscuro')) {
      themeMode.value = ThemeMode.dark;
      return;
    }
    themeMode.value = ThemeMode.light;
  }

  static String labelFromThemeMode(ThemeMode mode) {
    return mode == ThemeMode.dark ? 'Oscuro' : 'Claro (GreenPulse)';
  }
}
