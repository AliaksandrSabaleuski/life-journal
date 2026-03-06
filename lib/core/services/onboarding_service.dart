import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  OnboardingService._();

  // Версионируем ключ, чтобы при изменении сценария онбординга
  // показать его ещё раз существующим пользователям.
  static const String completedKey = 'onboarding_v2_completed';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completedKey, true);
  }
}

