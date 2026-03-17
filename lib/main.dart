import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/subscription_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await SubscriptionService.init();
  final completed = await OnboardingService.isCompleted();
  runApp(JournalApp(onboardingCompleted: completed));
}
