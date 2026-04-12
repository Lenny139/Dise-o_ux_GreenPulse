import 'package:flutter/material.dart';

class AppLanguageController {
  AppLanguageController._();

  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('es'));

  static bool get isEnglish => locale.value.languageCode == 'en';

  static void applyLanguageLabel(String value) {
    final normalized = value.toLowerCase().trim();
    if (normalized.contains('english') || normalized.contains('inglés')) {
      locale.value = const Locale('en');
      return;
    }
    locale.value = const Locale('es');
  }

  static String labelFromLocale(Locale value) {
    return value.languageCode == 'en' ? 'English' : 'Español';
  }
}
