import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
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
      title: 'Дневник привычек',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('ru');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('ru');
      },
      home: onboardingCompleted ? const MainShell() : const OnboardingScreen(),
    );
  }
}
