/// Локальные переключатели для отладки. Перед релизом всё должно быть выключено.
abstract final class DevOverrides {
  /// Явно в коде: поставь `true` — каждый старт с онбордингом (как первый запуск).
  static const bool forceFirstLaunchInCode = false;

  /// Или без правки файла: `flutter run --dart-define=FORCE_FIRST_LAUNCH=true`
  static const bool _forceFirstLaunchFromEnv = bool.fromEnvironment(
    'FORCE_FIRST_LAUNCH',
    defaultValue: false,
  );

  static bool get forceFirstLaunch =>
      forceFirstLaunchInCode || _forceFirstLaunchFromEnv;

  /// Демо-привычки и логи за прошлые дни (только debug, см. [main]).
  /// Или без правки файла: `--dart-define=STATS_DEMO_SEED=true`.
  static const bool statsDemoSeedInCode = true;

  static const bool _statsDemoSeedFromEnv = bool.fromEnvironment(
    'STATS_DEMO_SEED',
    defaultValue: false,
  );

  static bool get injectStatsDemoSeed =>
      statsDemoSeedInCode || _statsDemoSeedFromEnv;
}
