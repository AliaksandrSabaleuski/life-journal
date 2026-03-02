/// Запись о выполнении/срыве за день.
class HabitLog {
  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    this.value,
    this.isCompleted,
  });

  final String id;
  final String habitId;
  final DateTime date;
  /// Для счётчика/таймера/лимита — число (раз, минуты и т.д.).
  final double? value;
  /// Для бинарных: true = сделал/удержался, false = не сделал/сорвался.
  final bool? isCompleted;

  /// Дата без времени для сравнения «за день».
  DateTime get dateOnly => DateTime(date.year, date.month, date.day);
}
