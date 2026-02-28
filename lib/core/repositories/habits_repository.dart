import '../models/habit.dart';
import 'package:flutter/material.dart';

/// Репозиторий привычек. Пока возвращает только преднастроенный мок-набор.
class HabitsRepository {
  HabitsRepository();

  /// Список привычек для отображения (предустановленные + позже пользовательские).
  Future<List<Habit>> getHabits() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _mockHabits;
  }

  static final List<Habit> _mockHabits = [
    Habit(
      id: '1',
      name: 'Курение',
      icon: Icons.smoke_free,
      color: Colors.pink,
      currentGoalDays: 7,
      attemptCount: 5,
      recordDays: 9,
    ),
    Habit(
      id: '2',
      name: 'Сладости',
      icon: Icons.cake,
      color: Colors.orange,
      currentGoalDays: 14,
      attemptCount: 3,
      recordDays: 12,
    ),
    Habit(
      id: '3',
      name: 'Алкоголь',
      icon: Icons.local_bar,
      color: Colors.blue,
      currentGoalDays: 30,
      attemptCount: 1,
      recordDays: 21,
    ),
  ];
}
