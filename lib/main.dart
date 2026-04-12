import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/dev_overrides.dart';
import 'core/dev/stats_demo_seed.dart';
import 'core/config/ga_keys.dart';
import 'core/services/analytics_service.dart';
import 'core/services/iap_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/subscription_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GameAnalytics: configure in lib/core/config/ga_keys.dart or via --dart-define
  const gameKey = String.fromEnvironment('GA_GAME_KEY', defaultValue: gaGameKey);
  const secretKey = String.fromEnvironment('GA_SECRET_KEY', defaultValue: gaSecretKey);
  await AnalyticsService.instance.init(gameKey: gameKey, secretKey: secretKey);

  await NotificationService.instance.init();
  await SubscriptionService.init();
  await IapService.instance.init();
  if (kDebugMode && DevOverrides.injectStatsDemoSeed) {
    await injectStatsDemoSeedIfEnabled();
  }
  final completed = DevOverrides.forceFirstLaunch
      ? false
      : await OnboardingService.isCompleted();
  runApp(JournalApp(onboardingCompleted: completed));
}
