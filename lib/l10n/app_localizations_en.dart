// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'About Me: Habit tracker';

  @override
  String get newEventTitle => 'New event for today';

  @override
  String get newEventHint => 'What mattered today?';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get closeButton => 'Close';

  @override
  String get addButton => 'Add';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get subscriptionBody =>
      'Subscribe so you don\'t lose your journal.\n\n(Placeholder for now.)';

  @override
  String get noEventsForDay =>
      'No entries for this day yet.\nTap + to add the first one.';

  @override
  String get todayLabel => 'Today';

  @override
  String get backToTodayTooltip => 'Back to today';

  @override
  String get searchHint => 'Search';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPlaceholder =>
      'Theme, language, sounds, and more will live here.';

  @override
  String get tabMain => 'Home';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabStats => 'Statistics';

  @override
  String get tabAssistant => 'Assistant';

  @override
  String get assistantInDevelopmentTitle => 'Assistant in development';

  @override
  String get assistantInDevelopmentBody =>
      'This feature will arrive in one of the next updates. We\'re already working on it!';

  @override
  String get assistantGotItButton => 'Got it';

  @override
  String get newBlockTitle => 'New';

  @override
  String get motivationalText =>
      'Keys to a more productive life are in your hands. Start a new habit today!';

  @override
  String get calendarViewMonth => 'Month';

  @override
  String get calendarViewYear => 'Year';

  @override
  String get goalTypeTime => 'Time';

  @override
  String get goalTypeQuantity => 'Quantity';

  @override
  String get goalTypeTask => 'Task';

  @override
  String get repeatNever => 'Does not repeat';

  @override
  String get recordInactive => 'Inactive';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get startTimeLabel => 'Start';

  @override
  String get endTimeLabel => 'End';

  @override
  String get addRecordTitle => 'New entry';

  @override
  String get goodHabitLabel => 'Good habit';

  @override
  String get badHabitLabel => 'Bad habit';

  @override
  String get chooseHabitTypeTitle => 'Habit type';

  @override
  String get chooseHabitTypeHint => 'Choose what kind of habit you want to add';

  @override
  String get addHabitTitle => 'Add habit';

  @override
  String get createHabitButton => 'Create habit';

  @override
  String get previewTitle => 'Preview';

  @override
  String get cardColorLabel => 'Card color';

  @override
  String get repeatabilityLabel => 'Repeat';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatPickDays => 'Pick days';

  @override
  String get createYourOwn => 'Create your own';

  @override
  String get customTitle => 'Custom habit';

  @override
  String get limitTime => 'Time limit';

  @override
  String get limitCount => 'Count limit';

  @override
  String get customHabitNameLabel => 'Habit name';

  @override
  String get minutesPerDay => 'Minutes per day';

  @override
  String get amountPerDay => 'Amount per day';

  @override
  String get unitShort => 'Unit';

  @override
  String get minShort => 'min';

  @override
  String get pickDaysTitle => 'Pick days';

  @override
  String get okButton => 'OK';

  @override
  String get editHabitTitle => 'Edit habit';

  @override
  String get editHabitNameLabel => 'Name';

  @override
  String get editHabitNameHint => 'Keep the name short and specific';

  @override
  String get editHabitCardColor => 'Card color';

  @override
  String get editHabitTypePrefix => 'Type:';

  @override
  String get editHabitExecutionKind => 'Completion';

  @override
  String get editHabitGoalRow => 'Goal:';

  @override
  String get editHabitUnitRow => 'Unit:';

  @override
  String get editHabitBinaryDetail =>
      'Goal is to mark completion once per day (no numeric target).';

  @override
  String get editHabitTimeGoalHint => 'How much time per day';

  @override
  String get editHabitCountGoalHint => 'How many times (or units) per day';

  @override
  String get unitMinutesLong => 'minutes';

  @override
  String get unitHoursLong => 'hours';

  @override
  String get editDeleteHabitConfirmTitle => 'Delete habit?';

  @override
  String get editDeleteHabitConfirmBody =>
      'The habit will be hidden from active and moved to inactive.';

  @override
  String get deleteButton => 'Delete';

  @override
  String get editHabitOneTimeTitle => 'One-off event';

  @override
  String get editHabitOneTimeSubtitle => 'Single calendar day, no repeat';

  @override
  String get habitPeriodStart => 'Start date';

  @override
  String get habitPeriodEnd => 'End date';
}
