import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/logic/habit_streak.dart';
import 'package:flutter_application_1/core/models/habit.dart';
import 'package:flutter_application_1/core/models/habit_log.dart';

Habit _dailyHabit({DateTime? startDate}) {
  return Habit(
    id: 'h1',
    name: 'Test',
    direction: HabitDirection.good,
    measurement: HabitMeasurement.binary,
    goal: const HabitGoal.noGoal(),
    color: const Color(0xFF000000),
    repeatDays: const [],
    startDate: startDate,
  );
}

HabitLog _log(DateTime day, {required bool done}) {
  return HabitLog(
    id: 'l_${day.millisecondsSinceEpoch}',
    habitId: 'h1',
    date: DateTime(day.year, day.month, day.day, 12),
    isCompleted: done,
  );
}

void main() {
  test('currentAt: три подряд запланированных дня с успехом = 3', () {
    final h = _dailyHabit(startDate: DateTime(2026, 4, 1));
    final d0 = DateTime(2026, 4, 10);
    final logs = [
      _log(d0, done: true),
      _log(d0.add(const Duration(days: 1)), done: true),
      _log(d0.add(const Duration(days: 2)), done: true),
    ];
    expect(
      HabitStreak.currentAt(h, logs, d0.add(const Duration(days: 2))),
      3,
    );
  });

  test('currentAt: провал вчера сбрасывает серию сегодня', () {
    final h = _dailyHabit(startDate: DateTime(2026, 4, 1));
    final mon = DateTime(2026, 4, 7);
    final tue = DateTime(2026, 4, 8);
    final wed = DateTime(2026, 4, 9);
    final logs = [
      _log(mon, done: true),
      _log(tue, done: false),
      _log(wed, done: true),
    ];
    expect(HabitStreak.currentAt(h, logs, wed), 1);
  });

  test('currentAt: сегодня без лога не обрывает — считаем вчера', () {
    final h = _dailyHabit(startDate: DateTime(2026, 4, 1));
    final y = DateTime(2026, 4, 9);
    final t = DateTime(2026, 4, 10);
    final logs = [
      _log(y, done: true),
    ];
    expect(HabitStreak.currentAt(h, logs, t), 1);
  });

  test('longestInRange: максимум из двух отрезков', () {
    final h = _dailyHabit(startDate: DateTime(2026, 4, 1));
    var day = DateTime(2026, 4, 1);
    final logs = <HabitLog>[];
    for (var i = 0; i < 5; i++) {
      logs.add(_log(day, done: true));
      day = day.add(const Duration(days: 1));
    }
    day = day.add(const Duration(days: 1));
    logs.add(_log(day, done: false));
    for (var i = 0; i < 2; i++) {
      day = day.add(const Duration(days: 1));
      logs.add(_log(day, done: true));
    }
    expect(
      HabitStreak.longestInRange(
        h,
        logs,
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 30),
      ),
      5,
    );
  });

  test('currentInRange: не выходит за границы периода', () {
    final h = _dailyHabit(startDate: DateTime(2026, 4, 1));
    final weekStart = DateTime(2026, 4, 7);
    final weekEnd = DateTime(2026, 4, 13);
    final prev = weekStart.subtract(const Duration(days: 1));
    final logs = [
      _log(prev, done: true),
      _log(weekStart, done: true),
      _log(weekStart.add(const Duration(days: 1)), done: true),
    ];
    expect(
      HabitStreak.currentInRange(h, logs, weekStart, weekEnd, weekStart.add(const Duration(days: 1))),
      2,
    );
  });

  test('currentInRange: как currentAt, но cap по концу периода', () {
    final h = _dailyHabit(startDate: DateTime(2026, 4, 1));
    final start = DateTime(2026, 4, 1);
    final end = DateTime(2026, 4, 30);
    final t = DateTime(2026, 4, 10);
    final logs = [
      _log(t.subtract(const Duration(days: 1)), done: true),
    ];
    expect(HabitStreak.currentInRange(h, logs, start, end, t), 1);
  });
}
