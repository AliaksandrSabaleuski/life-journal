import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'locale_controller.dart';
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
    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLocaleController.locale,
      builder: (context, debugLocale, _) {
        return MaterialApp(
          title: 'Habit Run',
          theme: AppTheme.light,
          darkTheme: AppTheme.light,
          themeMode: ThemeMode.light,
          locale: debugLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
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
      },
    );
  }
}
