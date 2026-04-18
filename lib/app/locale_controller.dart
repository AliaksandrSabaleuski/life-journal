import 'package:flutter/widgets.dart';

class AppLocaleController {
  AppLocaleController._();

  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);
}

