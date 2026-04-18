import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/locale_controller.dart';
import 'core/config/ga_keys.dart';
import 'core/services/analytics_service.dart';
import 'core/services/iap_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/subscription_service.dart';

/// Должен совпадать с ключом в `SettingsScreen`.
const _prefsAppLanguageKey = 'app_language';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GameAnalytics: configure in lib/core/config/ga_keys.dart or via --dart-define
  const gameKey = String.fromEnvironment('GA_GAME_KEY', defaultValue: gaGameKey);
  const secretKey = String.fromEnvironment('GA_SECRET_KEY', defaultValue: gaSecretKey);
  await AnalyticsService.instance.init(gameKey: gameKey, secretKey: secretKey);

  await NotificationService.instance.init();
  await SubscriptionService.init();
  await IapService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString(_prefsAppLanguageKey);
  if (lang != null && (lang == 'ru' || lang == 'en')) {
    AppLocaleController.locale.value = Locale(lang);
  }

  final completed = await OnboardingService.isCompleted();
  runApp(JournalApp(onboardingCompleted: completed));
}
