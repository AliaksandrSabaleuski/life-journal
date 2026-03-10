import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис темы: хранит предпочтение светлой/тёмной темы в SharedPreferences.
class ThemeService {
  ThemeService._();

  static const String _darkModeKey = 'theme_dark_mode';

  static final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);
  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    darkModeNotifier.value = prefs.getBool(_darkModeKey) ?? false;
    _loaded = true;
  }

  static bool get isDarkMode => darkModeNotifier.value;

  static Future<void> setDarkMode(bool value) async {
    if (darkModeNotifier.value == value) return;
    darkModeNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }
}
