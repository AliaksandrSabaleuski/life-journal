import '../models/habit_log.dart';

/// Репозиторий логов выполнения привычек. Пока в памяти.
class HabitLogsRepository {
  HabitLogsRepository() {
    _seedMockLogs();
  }

  final List<HabitLog> _logs = [];

  Future<List<HabitLog>> getLogsForHabit(String habitId) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    DateTime habitDate(DateTime d) => DateTime(d.year, d.month, d.day);
    final now = habitDate(DateTime.now());
    return _logs
        .where((l) => l.habitId == habitId && habitDate(l.date).isAtSameMomentAs(now))
        .toList();
  }

  Future<HabitLog?> getTodayLog(String habitId) async {
    final list = await getLogsForHabit(habitId);
    return list.isEmpty ? null : list.last;
  }

  Future<void> addLog(HabitLog log) async {
    _logs.add(log);
  }

  Future<void> updateOrAddLog(HabitLog log) async {
    final i = _logs.indexWhere((l) =>
        l.habitId == log.habitId &&
        l.dateOnly.isAtSameMomentAs(log.dateOnly));
    if (i >= 0) {
      _logs[i] = log;
    } else {
      _logs.add(log);
    }
  }

  Future<List<HabitLog>> getLogsForHabitInRange(
    String habitId,
    DateTime start,
    DateTime end,
  ) async {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return _logs.where((l) {
      if (l.habitId != habitId) return false;
      final d = l.dateOnly;
      return !d.isBefore(startDay) && !d.isAfter(endDay);
    }).toList();
  }

  void _seedMockLogs() {
    final now = DateTime.now();
    DateTime day(int daysAgo, {int hour = 9}) {
      final d = now.subtract(Duration(days: daysAgo));
      return DateTime(d.year, d.month, d.day, hour);
    }

    // 1) "Стакан воды (месяц)" — полгода истории с разной дисциплиной.
    // Последние 30 дней: чередование успех/пропуск.
    for (var i = 0; i < 30; i++) {
      final completed = i.isEven;
      _logs.add(
        HabitLog(
          id: 'log_water_recent_$i',
          habitId: 'habit_month_water',
          date: day(i),
          value: completed ? 5 : 2,
          isCompleted: completed,
        ),
      );
    }
    // Ещё 5-6 отметок распределены по прошлым месяцам.
    const offsetsWater = [35, 42, 60, 90, 120, 150];
    for (final offset in offsetsWater) {
      _logs.add(
        HabitLog(
          id: 'log_water_past_$offset',
          habitId: 'habit_month_water',
          date: day(offset),
          value: 5,
          isCompleted: true,
        ),
      );
    }

    // 2) "Прогулка (неделя, активна)" — несколько недель назад почти идеальная,
    // текущая неделя с парой пропусков.
    for (var i = 0; i < 7; i++) {
      _logs.add(
        HabitLog(
          id: 'log_walk_curr_$i',
          habitId: 'habit_week_active',
          date: day(i),
          value: 7,
          isCompleted: i != 2 && i != 5,
        ),
      );
    }
    for (var i = 8; i < 15; i++) {
      _logs.add(
        HabitLog(
          id: 'log_walk_prev_$i',
          habitId: 'habit_week_active',
          date: day(i),
          value: 7,
          isCompleted: true,
        ),
      );
    }

    // 3) "Чтение (неделя, завершена)" — прошлая неделя с редкими успехами.
    for (var i = 14; i < 21; i++) {
      final completed = i % 3 == 0;
      _logs.add(
        HabitLog(
          id: 'log_read_$i',
          habitId: 'habit_week_finished',
          date: day(i, hour: 21),
          value: completed ? 25 : 5,
          isCompleted: completed,
        ),
      );
    }

    // 4) "Экран менее 1 часа" — много разнотипных дней в последнем месяце.
    for (var i = 0; i < 30; i++) {
      final good = i % 4 != 0;
      _logs.add(
        HabitLog(
          id: 'log_screen_$i',
          habitId: 'habit_timer_screen',
          date: day(i, hour: 23),
          value: good ? 40 + (i % 20) : 90 + (i % 60),
          isCompleted: good,
        ),
      );
    }

    // 5) "Сигареты" — частые логи с разными исходами за последние 45 дней.
    for (var i = 0; i < 45; i++) {
      final ok = i % 5 != 0;
      _logs.add(
        HabitLog(
          id: 'log_smoke_$i',
          habitId: 'habit_bad_smoke',
          date: day(i),
          value: ok ? 3 : 9,
          isCompleted: ok,
        ),
      );
    }

  }
}
