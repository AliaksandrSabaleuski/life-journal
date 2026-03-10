import '../models/habit_log.dart';
import '../models/habit.dart';
import '../persistence/habit_logs_persistence.dart';

/// Репозиторий логов выполнения привычек.
/// Хранит данные в памяти и сохраняет в SharedPreferences.
class HabitLogsRepository {
  HabitLogsRepository();

  final List<HabitLog> _logs = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (!_loaded) {
      final loaded = await HabitLogsPersistence.load();
      _logs.clear();
      _logs.addAll(loaded);
      _loaded = true;
    }
  }

  Future<void> _persist() async {
    await HabitLogsPersistence.save(_logs);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  double _goalValue(Habit habit) {
    switch (habit.goal.kind) {
      case HabitGoalKind.target:
        return habit.goal.value ?? 1.0;
      case HabitGoalKind.noGoal:
        return 1.0;
    }
  }

  HabitLog? _findLog(String habitId, DateTime dateOnly) {
    final i = _logs.indexWhere((l) =>
        l.habitId == habitId && l.dateOnly.isAtSameMomentAs(dateOnly));
    if (i < 0) return null;
    return _logs[i];
  }

  Future<List<HabitLog>> getLogsForHabit(String habitId) async {
    await _ensureLoaded();
    return _logs.where((l) => l.habitId == habitId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<HabitLog?> getTodayLog(String habitId) async {
    return getLogForDate(habitId, DateTime.now());
  }

  Future<HabitLog?> getLogForDate(String habitId, DateTime date) async {
    await _ensureLoaded();
    final day = _dateOnly(date);
    return _findLog(habitId, day);
  }

  Future<void> addLog(HabitLog log) async {
    await _ensureLoaded();
    _logs.add(log);
    await _persist();
  }

  Future<void> updateOrAddLog(HabitLog log) async {
    await _ensureLoaded();
    final i = _logs.indexWhere((l) =>
        l.habitId == log.habitId &&
        l.dateOnly.isAtSameMomentAs(log.dateOnly));
    if (i >= 0) {
      _logs[i] = log;
    } else {
      _logs.add(log);
    }
    await _persist();
  }

  /// Закрывает прошедшие дни (строго раньше сегодняшнего): если не отмечено и
  /// условия не выполнены — ставит fail (`isCompleted=false`).
  /// Если прогресс по числу/времени уже достиг цели — ставит success (`isCompleted=true`),
  /// даже если пользователь не нажал «Отметить».
  ///
  /// Чтобы не раздувать историю, ограничиваемся последними [maxDaysBack] днями.
  Future<void> finalizePastDays(
    List<Habit> habits, {
    DateTime? now,
    int maxDaysBack = 60,
  }) async {
    await _ensureLoaded();
    final n = now ?? DateTime.now();
    final today = _dateOnly(n);
    final start = today.subtract(Duration(days: maxDaysBack));
    final yesterday = today.subtract(const Duration(days: 1));
    if (yesterday.isBefore(start)) return;

    for (final habit in habits) {
      // События тоже сюда попадают (они в этом прототипе — те же Habit).
      var d = start;
      while (!d.isAfter(yesterday)) {
        if (!habit.isScheduledForDate(d)) {
          d = d.add(const Duration(days: 1));
          continue;
        }

        final existing = _findLog(habit.id, d);

        // Если день уже явно закрыт (success/fail) — не трогаем.
        if (existing?.isCompleted == true || existing?.isCompleted == false) {
          d = d.add(const Duration(days: 1));
          continue;
        }

        final goal = _goalValue(habit);
        final value = existing?.value;
        bool achieved;

        if (habit.measurement == HabitMeasurement.binary) {
          achieved = existing?.isCompleted == true;
        } else {
          final v = value ?? 0.0;
          achieved = v >= goal;
        }

        final finalized = HabitLog(
          id: existing?.id ?? 'final_${habit.id}_${d.millisecondsSinceEpoch}',
          habitId: habit.id,
          date: DateTime(d.year, d.month, d.day, 23, 59),
          value: existing?.value,
          isCompleted: achieved,
        );
        await updateOrAddLog(finalized);

        d = d.add(const Duration(days: 1));
      }
    }
    await _persist();
  }

  Future<List<HabitLog>> getLogsForHabitInRange(
    String habitId,
    DateTime start,
    DateTime end,
  ) async {
    await _ensureLoaded();
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return _logs.where((l) {
      if (l.habitId != habitId) return false;
      final d = l.dateOnly;
      return !d.isBefore(startDay) && !d.isAfter(endDay);
    }).toList();
  }

}
