import 'package:flutter/material.dart';

/// Модель привычки для главного меню и дальнейшей логики.
class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.currentGoalDays,
    required this.attemptCount,
    required this.recordDays,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  /// Текущая цель в днях (например, 7 дней подряд).
  final int currentGoalDays;
  /// Номер текущей попытки (счётчик).
  final int attemptCount;
  /// Рекорд в днях.
  final int recordDays;
}
