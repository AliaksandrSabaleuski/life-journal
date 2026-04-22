/// Русские строки приложения (без локализации/переключения языка).
abstract final class StringsRu {
  // Общие
  static const appTitle = 'About Me';
  static const cancel = 'Отмена';
  static const ok = 'OK';
  static const save = 'Сохранить';
  static const close = 'Закрыть';
  static const delete = 'Удалить';

  // Вкладки / тултипы
  static const tabMain = 'Главная';
  static const tabCalendar = 'Календарь';
  static const tabStats = 'Статистика';
  static const tabAssistant = 'Помощник';
  static const settings = 'Настройки';
  static const settingsTooltip = 'Настройки';
  static const backToTodayTooltip = 'Вернуться к сегодня';
  static const subscriptionTitle = 'Подписка';
  static const subscriptionBody =
      'Подписка открывает безлимитные привычки и события, а также даёт доступ к подробной статистике.';

  // Календарь
  static const calendarViewMonth = 'Месяц';
  static const calendarViewYear = 'Год';

  // Выбор типа привычки
  static const chooseHabitTypeTitle = 'Выбор привычки';
  static const chooseHabitTypeHint = 'Выбери направление привычки: хорошая или плохая.';
  static const goodHabitLabel = 'Хорошая';
  static const badHabitLabel = 'Плохая';

  // Редактирование привычки
  static const unitMinutesLong = 'Минуты';
  static const unitHoursLong = 'Часы';
  static const pickDaysTitle = 'Выбрать дни';
  static const editHabitTitle = 'Редактировать';
  static const editHabitNameLabel = 'Название';
  static const editHabitNameHint = 'Например: Прогулка';
  static const editHabitTypePrefix = 'Тип:';
  static const editHabitGoalRow = 'Цель:';
  static const editHabitUnitRow = 'Единица:';
  static const editHabitExecutionKind = 'Выполнение';
  static const goalTypeTime = 'Время';
  static const goalTypeQuantity = 'Количество';
  static const editHabitBinaryDetail = 'Отмечай выполнение одним нажатием.';
  static const editHabitTimeGoalHint = 'Минут в день';
  static const editHabitCountGoalHint = 'Сколько раз';
  static const cardColorLabel = 'Цвет карточки';
  static const editHabitOneTimeTitle = 'Одноразовая';
  static const editHabitOneTimeSubtitle = 'Только на один день';
  static const repeatabilityLabel = 'Повторяемость';
  static const repeatDaily = 'Каждый день';
  static const repeatPickDays = 'Выбрать дни';
  static const editDeleteHabitConfirmTitle = 'Удалить привычку?';
  static const editDeleteHabitConfirmBody =
      'Привычка будет скрыта из списка. История останется.';
  static const previewTitle = 'Превью';
  static const habitPeriodEnd = 'Окончание';

  // Визард добавления
  static const reminderLabel = 'Напоминание';

  // Статистика
  static const statsPeriodWeek = 'Неделя';
  static const statsPeriodMonth = 'Месяц';
  static const statsPeriodYear = 'Год';
  static const statsEmptyTitle = 'Пока нет данных';
  static const statsEmptyBody = 'Добавь привычки и отмечай прогресс, чтобы видеть статистику.';
  static const statsMotivationFooter = 'Продолжай — и результат обязательно будет.';
  static const statsTotalCompletedLabel = 'Выполнено';
  static const statsBestStreakLabel = 'Лучшая серия';
  static const statsHabitTableHabit = 'Привычка';
  static const statsHabitTableCount = 'Вып.';
  static const statsHabitTableStreak = 'Серия';

  static String statsGoalsCount(int n) => '$n';
  static String statsStreakDays(int days) => '$days дн.';

  // Ассистент (диалог)
  static const assistantInDevelopmentTitle = 'Помощник в разработке';
  static const assistantInDevelopmentBody =
      'Этот раздел пока в разработке. Скоро здесь появятся подсказки и рекомендации.';
  static const assistantGotItButton = 'Понял';
}

