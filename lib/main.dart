import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await ThemeService.init();
  final completed = await OnboardingService.isCompleted();
  runApp(JournalApp(onboardingCompleted: completed));
}
