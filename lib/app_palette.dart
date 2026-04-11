import 'package:flutter/material.dart';

class AppPalette {
  static const Color primary = Color(0xFF2D6A4F);
  static const Color secondary = Color(0xFF40916C);
  static const Color accent = Color(0xFF52B788);
  static const Color background = Color(0xFFF6FAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B4332);
  static const Color textSecondary = Color(0xFF4F6D5E);
  static const Color border = Color(0xFFD8E7DF);

  static Color textPrimaryOf(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color textSecondaryOf(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color softSurfaceOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF22342C)
        : const Color(0xFFEAF6F0);
  }

  static Color viewportBackgroundOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121916)
        : AppPalette.background;
  }

  static Color navIndicatorOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A3B34)
        : const Color(0xFFDCEFE5);
  }
}
