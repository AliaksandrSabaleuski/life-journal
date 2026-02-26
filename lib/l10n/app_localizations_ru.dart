// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Дневник событий';

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
      'Подпишись, чтобы не потерять свой дневник.\\n\\n(Пока без реального функционала — просто заглушка.)';

  @override
  String get noEventsForDay =>
      'Пока нет записей за выбранный день.\\nНажми на +, чтобы добавить первую.';

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get backToTodayTooltip => 'Вернуться к сегодня';
}
