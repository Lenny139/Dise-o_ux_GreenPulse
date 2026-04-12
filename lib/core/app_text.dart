import 'app_language_controller.dart';

class AppText {
  AppText._();

  static String t({required String es, required String en}) {
    return AppLanguageController.isEnglish ? en : es;
  }
}
