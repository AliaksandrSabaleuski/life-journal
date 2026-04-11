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
}
