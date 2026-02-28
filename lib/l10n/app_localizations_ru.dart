// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Дневник привычек';

  @override
  String get newEventTitle => 'Новое событие за сегодня';

  @override
  String get newEventHint => 'Что важного произошло?';

  @override
  String get cancelButton => 'Отмена';

  @override
  String get saveButton => 'Сохранить';

  @override
  String get closeButton => 'Закрыть';

  @override
  String get addButton => 'Добавить';

  @override
  String get subscriptionTitle => 'Подписка';

  @override
  String get subscriptionBody =>
      'Подпишись, чтобы не потерять свой дневник.\n\n(Пока без реального функционала — просто заглушка.)';

  @override
  String get noEventsForDay =>
      'Пока нет записей за выбранный день.\nНажми на +, чтобы добавить первую.';

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get backToTodayTooltip => 'Вернуться к сегодня';

  @override
  String get searchHint => 'Поиск';

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsPlaceholder =>
      'Здесь будут настройки темы, языка, звуков и др.';

  @override
  String get tabMain => 'Главная';

  @override
  String get tabCalendar => 'Календарь';

  @override
  String get tabStats => 'Статистика';

  @override
  String get tabAssistant => 'Помощник';

  @override
  String get newBlockTitle => 'Новое';

  @override
  String get motivationalText =>
      'Ключи к более продуктивному образу жизни в ваших руках. Начните новую привычку сегодня!';

  @override
  String get calendarViewMonth => 'Месяц';

  @override
  String get calendarViewYear => 'Год';
}
