import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'About Me'**
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
  /// **'Подписка открывает безлимитные привычки и события.'**
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
  /// **'Настройки'**
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
  /// **'Помощник в разработке'**
  String get assistantInDevelopmentTitle;

  /// No description provided for @assistantInDevelopmentBody.
  ///
  /// In ru, this message translates to:
  /// **'Эта функция появится в одном из ближайших обновлений. Мы уже работаем над ней!'**
  String get assistantInDevelopmentBody;

  /// No description provided for @assistantGotItButton.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get assistantGotItButton;

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

  /// No description provided for @addHabitTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить привычку'**
  String get addHabitTitle;

  /// No description provided for @createHabitButton.
  ///
  /// In ru, this message translates to:
  /// **'Создать привычку'**
  String get createHabitButton;

  /// No description provided for @previewTitle.
  ///
  /// In ru, this message translates to:
  /// **'Предпросмотр'**
  String get previewTitle;

  /// No description provided for @cardColorLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цвет карточки'**
  String get cardColorLabel;

  /// No description provided for @repeatabilityLabel.
  ///
  /// In ru, this message translates to:
  /// **'Повторимость'**
  String get repeatabilityLabel;

  /// No description provided for @repeatDaily.
  ///
  /// In ru, this message translates to:
  /// **'Ежедневно'**
  String get repeatDaily;

  /// No description provided for @repeatPickDays.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дни'**
  String get repeatPickDays;

  /// No description provided for @createYourOwn.
  ///
  /// In ru, this message translates to:
  /// **'Создать свою'**
  String get createYourOwn;

  /// No description provided for @customTitle.
  ///
  /// In ru, this message translates to:
  /// **'Своя привычка'**
  String get customTitle;

  /// No description provided for @limitTime.
  ///
  /// In ru, this message translates to:
  /// **'Лимит времени'**
  String get limitTime;

  /// No description provided for @limitCount.
  ///
  /// In ru, this message translates to:
  /// **'Лимит количества'**
  String get limitCount;

  /// No description provided for @customHabitNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название привычки'**
  String get customHabitNameLabel;

  /// No description provided for @minutesPerDay.
  ///
  /// In ru, this message translates to:
  /// **'Минут в день'**
  String get minutesPerDay;

  /// No description provided for @amountPerDay.
  ///
  /// In ru, this message translates to:
  /// **'Сколько в день'**
  String get amountPerDay;

  /// No description provided for @unitShort.
  ///
  /// In ru, this message translates to:
  /// **'Ед.'**
  String get unitShort;

  /// No description provided for @minShort.
  ///
  /// In ru, this message translates to:
  /// **'мин'**
  String get minShort;

  /// No description provided for @pickDaysTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дни'**
  String get pickDaysTitle;

  /// No description provided for @okButton.
  ///
  /// In ru, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @editHabitTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать привычку'**
  String get editHabitTitle;

  /// No description provided for @editHabitNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get editHabitNameLabel;

  /// No description provided for @editHabitNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Название должно быть коротким и конкретным'**
  String get editHabitNameHint;

  /// No description provided for @editHabitCardColor.
  ///
  /// In ru, this message translates to:
  /// **'Цвет карточки'**
  String get editHabitCardColor;

  /// No description provided for @editHabitTypePrefix.
  ///
  /// In ru, this message translates to:
  /// **'Тип:'**
  String get editHabitTypePrefix;

  /// No description provided for @editHabitExecutionKind.
  ///
  /// In ru, this message translates to:
  /// **'Выполнение'**
  String get editHabitExecutionKind;

  /// No description provided for @editHabitGoalRow.
  ///
  /// In ru, this message translates to:
  /// **'Цель:'**
  String get editHabitGoalRow;

  /// No description provided for @editHabitUnitRow.
  ///
  /// In ru, this message translates to:
  /// **'Единица:'**
  String get editHabitUnitRow;

  /// No description provided for @editHabitBinaryDetail.
  ///
  /// In ru, this message translates to:
  /// **'Цель — отметить выполнение за день (без числового лимита).'**
  String get editHabitBinaryDetail;

  /// No description provided for @editHabitTimeGoalHint.
  ///
  /// In ru, this message translates to:
  /// **'Сколько времени в день'**
  String get editHabitTimeGoalHint;

  /// No description provided for @editHabitCountGoalHint.
  ///
  /// In ru, this message translates to:
  /// **'Сколько раз (или единиц) в день'**
  String get editHabitCountGoalHint;

  /// No description provided for @unitMinutesLong.
  ///
  /// In ru, this message translates to:
  /// **'минуты'**
  String get unitMinutesLong;

  /// No description provided for @unitHoursLong.
  ///
  /// In ru, this message translates to:
  /// **'часы'**
  String get unitHoursLong;

  /// No description provided for @editDeleteHabitConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить привычку?'**
  String get editDeleteHabitConfirmTitle;

  /// No description provided for @editDeleteHabitConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Привычка будет скрыта из списка активных и перейдёт в раздел неактивных.'**
  String get editDeleteHabitConfirmBody;

  /// No description provided for @deleteButton.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get deleteButton;

  /// No description provided for @editHabitOneTimeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Одноразовое событие'**
  String get editHabitOneTimeTitle;

  /// No description provided for @editHabitOneTimeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Один день в календаре, без повторов'**
  String get editHabitOneTimeSubtitle;

  /// No description provided for @habitPeriodStart.
  ///
  /// In ru, this message translates to:
  /// **'Дата начала'**
  String get habitPeriodStart;

  /// No description provided for @habitPeriodEnd.
  ///
  /// In ru, this message translates to:
  /// **'Дата окончания'**
  String get habitPeriodEnd;

  /// No description provided for @statsPeriodWeek.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get statsPeriodWeek;

  /// No description provided for @statsPeriodMonth.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get statsPeriodMonth;

  /// No description provided for @statsPeriodYear.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get statsPeriodYear;

  /// No description provided for @statsTotalCompletedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено всего'**
  String get statsTotalCompletedLabel;

  /// No description provided for @statsGoalsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} целей'**
  String statsGoalsCount(int count);

  /// No description provided for @statsBestStreakLabel.
  ///
  /// In ru, this message translates to:
  /// **'Лучшая серия'**
  String get statsBestStreakLabel;

  /// No description provided for @statsStreakDays.
  ///
  /// In ru, this message translates to:
  /// **'{count} дн.'**
  String statsStreakDays(int count);

  /// No description provided for @statsMotivationFooter.
  ///
  /// In ru, this message translates to:
  /// **'Продолжай в том же духе!'**
  String get statsMotivationFooter;

  /// No description provided for @statsFilterTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр'**
  String get statsFilterTooltip;

  /// No description provided for @statsFilterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get statsFilterAll;

  /// No description provided for @statsFilterHabitsOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только привычки'**
  String get statsFilterHabitsOnly;

  /// No description provided for @statsFilterEventsOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только события'**
  String get statsFilterEventsOnly;

  /// No description provided for @statsScrollDownTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Вниз'**
  String get statsScrollDownTooltip;

  /// No description provided for @statsHabitProgressLine.
  ///
  /// In ru, this message translates to:
  /// **'{name} — {completed} из {total} дней | серия: {streak}'**
  String statsHabitProgressLine(
    Object name,
    int completed,
    int total,
    Object streak,
  );

  /// No description provided for @statsHabitTableHabit.
  ///
  /// In ru, this message translates to:
  /// **'Привычка'**
  String get statsHabitTableHabit;

  /// No description provided for @statsHabitTableCount.
  ///
  /// In ru, this message translates to:
  /// **'Дни'**
  String get statsHabitTableCount;

  /// No description provided for @statsHabitTableStreak.
  ///
  /// In ru, this message translates to:
  /// **'Серия'**
  String get statsHabitTableStreak;

  /// No description provided for @statsEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет данных'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Добавь привычки и отмечай дни — здесь появится статистика.'**
  String get statsEmptyBody;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
