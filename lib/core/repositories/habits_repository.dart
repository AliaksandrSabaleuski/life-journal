import 'package:flutter/material.dart';

import '../models/habit.dart';

/// Репозиторий привычек.
/// Пока хранит данные только в памяти. Синглтон, чтобы онбординг и MainShell
/// использовали один экземпляр (иначе базовые привычки, добавленные при онбординге, теряются).
class HabitsRepository {
  HabitsRepository._();
  static final HabitsRepository instance = HabitsRepository._();

  final List<Habit> _habits = [];

  Future<List<Habit>> getHabits() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return List<Habit>.from(_habits);
  }

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index >= 0) {
      _habits[index] = habit;
    }
  }

}
