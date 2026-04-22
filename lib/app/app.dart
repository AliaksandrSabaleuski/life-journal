import 'package:flutter/material.dart';

import 'strings_ru.dart';
import 'theme.dart';
import '../features/shell/presentation/main_shell.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';

/// Корневой виджет приложения: темы, локализация, начальный экран.
class JournalApp extends StatelessWidget {
  const JournalApp({
    super.key,
    required this.onboardingCompleted,
  });

  final bool onboardingCompleted;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: StringsRu.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: onboardingCompleted ? const MainShell() : const OnboardingScreen(),
    );
  }
}
