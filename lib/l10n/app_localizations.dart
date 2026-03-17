import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Дневник привычек'**
  String get appTitle;

  /// No description provided for @newEventTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новое событие за сегодня'**
  String get newEventTitle;

  /// No description provided for @newEventHint.
  ///
  /// In ru, this message translates to:
  /// **'Что важного произошло?'**
  String get newEventHint;

  /// No description provided for @cancelButton.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get saveButton;

  /// No description provided for @closeButton.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get closeButton;

  /// No description provided for @addButton.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get addButton;

  /// No description provided for @subscriptionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionBody.
  ///
  /// In ru, this message translates to:
  /// **'Подпишись, чтобы не потерять свой дневник.\n\n(Пока без реального функционала — просто заглушка.)'**
  String get subscriptionBody;

  /// No description provided for @noEventsForDay.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет записей за выбранный день.\nНажми на +, чтобы добавить первую.'**
  String get noEventsForDay;

  /// No description provided for @todayLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get todayLabel;

  /// No description provided for @backToTodayTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к сегодня'**
  String get backToTodayTooltip;

  /// No description provided for @searchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get searchHint;

  /// No description provided for @settingsTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTooltip;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Здесь будут настройки темы, языка, звуков и др.'**
  String get settingsPlaceholder;

  /// No description provided for @tabMain.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get tabMain;

  /// No description provided for @tabCalendar.
  ///
  /// In ru, this message translates to:
  /// **'Календарь'**
  String get tabCalendar;

  /// No description provided for @tabStats.
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get tabStats;

  /// No description provided for @tabAssistant.
  ///
  /// In ru, this message translates to:
  /// **'Помощник'**
  String get tabAssistant;

  /// No description provided for @assistantInDevelopmentTitle.
  ///
  /// In ru, this message translates to:
  /// **'В разработке'**
  String get assistantInDevelopmentTitle;

  /// No description provided for @assistantInDevelopmentBody.
  ///
  /// In ru, this message translates to:
  /// **'Функционал помощника в разработке. Выпуск состоится в ближайших обновлениях.'**
  String get assistantInDevelopmentBody;

  /// No description provided for @newBlockTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новое'**
  String get newBlockTitle;

  /// No description provided for @motivationalText.
  ///
  /// In ru, this message translates to:
  /// **'Ключи к более продуктивному образу жизни в ваших руках. Начните новую привычку сегодня!'**
  String get motivationalText;

  /// No description provided for @calendarViewMonth.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get calendarViewMonth;

  /// No description provided for @calendarViewYear.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get calendarViewYear;

  /// No description provided for @goalTypeTime.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get goalTypeTime;

  /// No description provided for @goalTypeQuantity.
  ///
  /// In ru, this message translates to:
  /// **'Количество'**
  String get goalTypeQuantity;

  /// No description provided for @goalTypeTask.
  ///
  /// In ru, this message translates to:
  /// **'Задача'**
  String get goalTypeTask;

  /// No description provided for @repeatNever.
  ///
  /// In ru, this message translates to:
  /// **'Не повторяется'**
  String get repeatNever;

  /// No description provided for @recordInactive.
  ///
  /// In ru, this message translates to:
  /// **'Неактивна'**
  String get recordInactive;

  /// No description provided for @reminderLabel.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание'**
  String get reminderLabel;

  /// No description provided for @startTimeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Старт'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Конец'**
  String get endTimeLabel;

  /// No description provided for @addRecordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новая запись'**
  String get addRecordTitle;

  /// No description provided for @goodHabitLabel.
  ///
  /// In ru, this message translates to:
  /// **'Хорошая привычка'**
  String get goodHabitLabel;

  /// No description provided for @badHabitLabel.
  ///
  /// In ru, this message translates to:
  /// **'Плохая привычка'**
  String get badHabitLabel;

  /// No description provided for @chooseHabitTypeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тип привычки'**
  String get chooseHabitTypeTitle;

  /// No description provided for @chooseHabitTypeHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите, какую привычку хотите добавить'**
  String get chooseHabitTypeHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
