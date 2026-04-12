import '../models/habit.dart';
import '../models/habit_log.dart';

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Расчёт серий по логам: только **запланированные** дни; пропуск незапланированных;
/// явный провал (`isCompleted == false`) обрывает цепочку.
abstract final class HabitStreak {
  /// Нижняя граница: не раньше [Habit.startDate] и не раньше первого лога.
  static DateTime earliestRelevantDay(Habit habit, List<HabitLog> logsForHabit) {
    final minLog = logsForHabit.isEmpty
        ? null
        : logsForHabit.map((l) => l.dateOnly).reduce((a, b) => a.isBefore(b) ? a : b);
    if (habit.startDate != null) {
      final s = _dayOnly(habit.startDate!);
      if (minLog == null) return s;
      return minLog.isBefore(s) ? s : minLog;
    }
    if (minLog != null) return minLog;
    return _dayOnly(DateTime.now());
  }

  /// Текущая серия подряд выполненных **запланированных** дней, считая от [asOf].
  ///
  /// - Выполнен день → +1 к счётчику.
  /// - Явный провал → цепочка обрывается (дальше не считаем).
  /// - Нет записи на **сегодня** ([asOf]) → день пропускаем (ещё можно отметить), смотрим вчера.
  /// - Нет записи на **прошлый** запланированный день → обрыв (после finalize там должен быть fail).
  static int currentAt(
    Habit habit,
    List<HabitLog> logsForHabit,
    DateTime asOf,
  ) {
    final byDay = {for (final l in logsForHabit) _dayOnly(l.date): l};
    final today = _dayOnly(asOf);
    final earliest = earliestRelevantDay(habit, logsForHabit);
    var d = today;
    var streak = 0;

    while (!d.isBefore(earliest)) {
      final hDay = habit.forDate(d);
      if (!hDay.isScheduledForDate(d)) {
        d = d.subtract(const Duration(days: 1));
        continue;
      }

      final log = byDay[d];
      if (log?.isCompleted == true) {
        streak++;
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      if (log?.isCompleted == false) {
        break;
      }

      if (_dayOnly(d) == today) {
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }
    return streak;
  }

  /// Текущая серия **только внутри** [rangeStart..rangeEnd]: от
  /// min(день([asOf]), конец периода) назад до начала периода.
  ///
  /// Правила те же, что у [currentAt], но дни раньше [rangeStart] не учитываются.
  static int currentInRange(
    Habit habit,
    List<HabitLog> logsForHabit,
    DateTime rangeStart,
    DateTime rangeEnd,
    DateTime asOf,
  ) {
    final start = _dayOnly(rangeStart);
    final end = _dayOnly(rangeEnd);
    final asOfDay = _dayOnly(asOf);
    final byDay = {for (final l in logsForHabit) _dayOnly(l.date): l};

    var cap = asOfDay.isBefore(end) ? asOfDay : end;
    if (cap.isBefore(start)) return 0;

    var d = cap;
    var streak = 0;

    while (!d.isBefore(start)) {
      final hDay = habit.forDate(d);
      if (!hDay.isScheduledForDate(d)) {
        d = d.subtract(const Duration(days: 1));
        continue;
      }

      final log = byDay[d];
      if (log?.isCompleted == true) {
        streak++;
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      if (log?.isCompleted == false) {
        break;
      }

      if (_dayOnly(d) == asOfDay) {
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }
    return streak;
  }

  /// Самая длинная серия успехов на отрезке [start..end] (по запланированным дням).
  static int longestInRange(
    Habit habit,
    List<HabitLog> logsForHabit,
    DateTime start,
    DateTime end,
  ) {
    final byDay = {for (final l in logsForHabit) _dayOnly(l.date): l};
    var best = 0;
    var run = 0;
    var d = _dayOnly(start);
    final last = _dayOnly(end);
    while (!d.isAfter(last)) {
      final hDay = habit.forDate(d);
      if (!hDay.isScheduledForDate(d)) {
        d = d.add(const Duration(days: 1));
        continue;
      }
      final log = byDay[d];
      if (log?.isCompleted == true) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
      d = d.add(const Duration(days: 1));
    }
    return best;
  }

  /// Максимальная серия за всё время (от [earliestRelevantDay] до [asOf]).
  static int longestAllTime(
    Habit habit,
    List<HabitLog> logsForHabit,
    DateTime asOf,
  ) {
    final start = earliestRelevantDay(habit, logsForHabit);
    final end = _dayOnly(asOf);
    if (end.isBefore(start)) return 0;
    return longestInRange(habit, logsForHabit, start, end);
  }
}
