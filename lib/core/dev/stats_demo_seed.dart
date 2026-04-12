import 'package:flutter/material.dart';

import '../config/dev_overrides.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../repositories/habit_logs_repository.dart';
import '../repositories/habits_repository.dart';

/// Стабильные id, чтобы сид был идемпотентным (повторный запуск не плодит дубликаты).
const statsDemoRitualId = 'stats_demo_ritual';
const statsDemoCounterId = 'stats_demo_counter';
const statsDemoTimerId = 'stats_demo_timer';
const statsDemoBadId = 'stats_demo_bad';
const statsDemoEventId = 'stats_demo_event';
const statsDemoWeekdaysId = 'stats_demo_weekdays';
const statsDemoInactiveId = 'stats_demo_inactive';
const statsDemoLateStartId = 'stats_demo_late_start';

/// Демо-данные для статистики: несколько привычек разных типов и явные логи
/// за ~60 прошлых дней (иначе [HabitLogsRepository.finalizePastDays] заполнит
/// пустые бинарные дни провалами и графики станут однотонными).
///
/// Включается в debug: [DevOverrides.statsDemoSeedInCode] или
/// `flutter run --dart-define=STATS_DEMO_SEED=true`.
Future<void> injectStatsDemoSeedIfEnabled() async {
  if (!DevOverrides.injectStatsDemoSeed) return;

  final habitsRepo = HabitsRepository.instance;
  final existing = await habitsRepo.getHabits();
  final haveId = existing.map((h) => h.id).toSet();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final h in _demoHabits(anchorDay: today)) {
    if (!haveId.contains(h.id)) {
      await habitsRepo.addHabit(h);
      haveId.add(h.id);
    }
  }
  final logsRepo = HabitLogsRepository();

  for (final log in _demoLogs(anchorDay: today)) {
    await logsRepo.updateOrAddLog(log);
  }
}

List<Habit> _demoHabits({required DateTime anchorDay}) {
  final lateStartDay = _dayAt(anchorDay, 14);
  return [
    Habit(
      id: statsDemoRitualId,
      name: '[Демо] Утренняя рутина',
      direction: HabitDirection.good,
      measurement: HabitMeasurement.binary,
      goal: const HabitGoal.noGoal(),
      color: const Color(0xFF2E7D32),
      icon: Icons.wb_sunny_outlined,
      repeatDays: const [],
    ),
    Habit(
      id: statsDemoCounterId,
      name: '[Демо] Приседания',
      direction: HabitDirection.good,
      measurement: HabitMeasurement.counted,
      goal: const HabitGoal.target(10),
      color: const Color(0xFF1565C0),
      icon: Icons.fitness_center_outlined,
      unit: 'раз',
      repeatDays: const [],
    ),
    Habit(
      id: statsDemoTimerId,
      name: '[Демо] Чтение',
      direction: HabitDirection.good,
      measurement: HabitMeasurement.timed,
      goal: const HabitGoal.target(30),
      color: const Color(0xFF6A1B9A),
      icon: Icons.menu_book_outlined,
      unit: 'мин',
      repeatDays: const [],
    ),
    Habit(
      id: statsDemoBadId,
      name: '[Демо] Сладкое после 20:00',
      direction: HabitDirection.bad,
      measurement: HabitMeasurement.binary,
      goal: const HabitGoal.noGoal(),
      color: const Color(0xFFC62828),
      icon: Icons.cake_outlined,
      repeatDays: const [],
    ),
    Habit(
      id: statsDemoEventId,
      name: '[Демо] Событие: тренировка с тренером',
      direction: HabitDirection.good,
      measurement: HabitMeasurement.binary,
      goal: const HabitGoal.noGoal(),
      color: const Color(0xFF00897B),
      icon: Icons.event_available_outlined,
      repeatDays: const [],
      isEvent: true,
    ),
    Habit(
      id: statsDemoWeekdaysId,
      name: '[Демо] Только будни — разминка',
      direction: HabitDirection.good,
      measurement: HabitMeasurement.binary,
      goal: const HabitGoal.noGoal(),
      color: const Color(0xFFEF6C00),
      icon: Icons.self_improvement_outlined,
      repeatDays: const [1, 2, 3, 4, 5],
    ),
    Habit(
      id: statsDemoInactiveId,
      name: '[Демо] Архив (неактивна)',
      direction: HabitDirection.good,
      measurement: HabitMeasurement.binary,
      goal: const HabitGoal.noGoal(),
      color: const Color(0xFF78909C),
      icon: Icons.inventory_2_outlined,
      repeatDays: const [],
      isActive: false,
    ),
    Habit(
      id: statsDemoLateStartId,
      name: '[Демо] Старт 2 недели назад',
      direction: HabitDirection.good,
      measurement: HabitMeasurement.binary,
      goal: const HabitGoal.noGoal(),
      color: const Color(0xFF5E35B1),
      icon: Icons.flag_outlined,
      repeatDays: const [],
      startDate: lateStartDay,
    ),
  ];
}

DateTime _dayAt(DateTime anchorDay, int daysAgo) {
  final d = DateTime(anchorDay.year, anchorDay.month, anchorDay.day)
      .subtract(Duration(days: daysAgo));
  return DateTime(d.year, d.month, d.day);
}

List<HabitLog> _demoLogs({required DateTime anchorDay}) {
  final out = <HabitLog>[];
  const maxAgo = 59;

  void addBinaryRange({
    required String habitId,
    required bool Function(DateTime day) dayIncluded,
    required bool Function(int daysAgo, DateTime day) success,
  }) {
    for (var daysAgo = 1; daysAgo <= maxAgo; daysAgo++) {
      final d = _dayAt(anchorDay, daysAgo);
      if (!dayIncluded(d)) continue;
      out.add(
        HabitLog(
          id: '${habitId}_$daysAgo',
          habitId: habitId,
          date: DateTime(d.year, d.month, d.day, 12),
          isCompleted: success(daysAgo, d),
        ),
      );
    }
  }

  void addCounterRange({
    required String habitId,
    required bool Function(DateTime day) dayIncluded,
  }) {
    for (var daysAgo = 1; daysAgo <= maxAgo; daysAgo++) {
      final d = _dayAt(anchorDay, daysAgo);
      if (!dayIncluded(d)) continue;
      final wave = (daysAgo % 5);
      final ok = wave != 1 && wave != 2;
      final value = ok ? 10.0 : 4.0;
      out.add(
        HabitLog(
          id: '${habitId}_$daysAgo',
          habitId: habitId,
          date: DateTime(d.year, d.month, d.day, 18),
          value: value,
          isCompleted: ok,
        ),
      );
    }
  }

  void addTimerRange({
    required String habitId,
    required bool Function(DateTime day) dayIncluded,
  }) {
    for (var daysAgo = 1; daysAgo <= maxAgo; daysAgo++) {
      final d = _dayAt(anchorDay, daysAgo);
      if (!dayIncluded(d)) continue;
      final ok = daysAgo % 4 != 0;
      final minutes = ok ? 35.0 : 12.0;
      out.add(
        HabitLog(
          id: '${habitId}_$daysAgo',
          habitId: habitId,
          date: DateTime(d.year, d.month, d.day, 21, 5),
          value: minutes,
          isCompleted: ok,
        ),
      );
    }
  }

  // Каждый день: ~70% успехов, зависимость от дня недели для «волн» на графике.
  addBinaryRange(
    habitId: statsDemoRitualId,
    dayIncluded: (_) => true,
    success: (daysAgo, day) =>
        daysAgo % 5 != 1 && (day.weekday + daysAgo) % 3 != 0,
  );

  addCounterRange(
    habitId: statsDemoCounterId,
    dayIncluded: (_) => true,
  );

  addTimerRange(
    habitId: statsDemoTimerId,
    dayIncluded: (_) => true,
  );

  // Плохая привычка: true = удержался, false = сорвался.
  addBinaryRange(
    habitId: statsDemoBadId,
    dayIncluded: (_) => true,
    success: (daysAgo, day) => daysAgo % 6 != 0 && day.weekday != DateTime.saturday,
  );

  // Событие: реже отмечаем (~2 раза в неделю).
  addBinaryRange(
    habitId: statsDemoEventId,
    dayIncluded: (_) => true,
    success: (daysAgo, _) =>
        daysAgo % 3 == 0 || daysAgo % 11 == 0,
  );

  addBinaryRange(
    habitId: statsDemoWeekdaysId,
    dayIncluded: (d) => d.weekday <= DateTime.friday,
    success: (daysAgo, day) =>
        day.weekday != DateTime.monday && daysAgo % 7 != 2,
  );

  final lateStart = _dayAt(anchorDay, 14);
  addBinaryRange(
    habitId: statsDemoLateStartId,
    dayIncluded: (d) => !d.isBefore(lateStart),
    success: (daysAgo, _) => daysAgo.isEven,
  );

  // Неактивная: мало точек в прошлом (для списка «неактивных»), планируемых дней нет.
  for (final daysAgo in [20, 35, 50]) {
    final d = _dayAt(anchorDay, daysAgo);
    out.add(
      HabitLog(
        id: '${statsDemoInactiveId}_$daysAgo',
        habitId: statsDemoInactiveId,
        date: DateTime(d.year, d.month, d.day, 10),
        isCompleted: daysAgo != 35,
      ),
    );
  }

  return out;
}
