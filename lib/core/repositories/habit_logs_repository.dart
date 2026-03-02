import '../models/habit_log.dart';

/// Репозиторий логов выполнения привычек. Пока в памяти.
class HabitLogsRepository {
  HabitLogsRepository();

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
}
