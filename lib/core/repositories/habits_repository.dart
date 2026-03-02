import 'package:flutter/material.dart';

import '../models/habit.dart';

/// Репозиторий привычек. Пока возвращает мок-набор.
class HabitsRepository {
  HabitsRepository();

  Future<List<Habit>> getHabits() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List.from(_mockHabits);
  }

  static final List<Habit> _mockHabits = [
    Habit(
      id: '1',
      name: 'Заправить кровать',
      direction: HabitDirection.good,
      measurement: HabitMeasurement.binary,
      goal: const HabitGoal.noGoal(),
      color: Colors.green,
      icon: Icons.bed,
      repeatDays: [1, 2, 3, 4, 5, 6, 7],
      isActive: true,
    ),
    Habit(
      id: '2',
      name: 'Стаканы воды',
      direction: HabitDirection.good,
      measurement: HabitMeasurement.counted,
      goal: const HabitGoal.target(5),
      unit: 'стак.',
      color: Colors.blue,
      icon: Icons.water_drop,
      repeatDays: [1, 2, 3, 4, 5, 6, 7],
      isActive: true,
    ),
    Habit(
      id: '3',
      name: 'Чтение',
      direction: HabitDirection.good,
      measurement: HabitMeasurement.timed,
      goal: const HabitGoal.target(20),
      unit: 'мин',
      color: Colors.indigo,
      icon: Icons.menu_book,
      repeatDays: [1, 3, 5, 7],
      isActive: true,
    ),
    Habit(
      id: '4',
      name: 'Не курить',
      direction: HabitDirection.bad,
      measurement: HabitMeasurement.binary,
      goal: const HabitGoal.noGoal(),
      color: Colors.orange,
      icon: Icons.smoke_free,
      repeatDays: [1, 2, 3, 4, 5, 6, 7],
      isActive: true,
    ),
  ];
}
