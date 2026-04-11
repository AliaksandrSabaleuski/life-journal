import 'package:flutter/widgets.dart';

class AppLocaleController {
  AppLocaleController._();

  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  static void toggleRuEn() {
    final current = locale.value;
    if (current?.languageCode == 'en') {
      locale.value = const Locale('ru');
    } else {
      locale.value = const Locale('en');
    }
  }
}

