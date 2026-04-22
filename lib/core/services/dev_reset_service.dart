import 'package:shared_preferences/shared_preferences.dart';

/// Временный dev-костыль: сбрасывает все данные приложения при каждом запуске.
///
/// ВАЖНО: это удаляет вообще все ключи SharedPreferences (привычки, логи, премиум,
/// настройки, язык, статус онбординга и т.д.).
abstract final class DevResetService {
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

