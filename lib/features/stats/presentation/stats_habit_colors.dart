import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';

/// «Без своего цвета», как в мастерах добавления/редактирования (`0x00000000`).
bool habitColorIsUnset(Color color) => color.value == 0;

/// Палитра для привычек без кастомного цвета — стабильно по `id`, без повторов пока хватает слотов.
const List<Color> kStatsDefaultPalette = [
  Color(0xFF5C6BC0), // indigo
  Color(0xFF26A69A), // teal
  Color(0xFFAB47BC), // purple
  Color(0xFF42A5F5), // blue
  Color(0xFFFF7043), // deep orange
  Color(0xFF78909C), // blue grey
  Color(0xFF8D6E63), // brown
  Color(0xFF7CB342), // light green
  Color(0xFFFFCA28), // amber
  Color(0xFFEC407A), // pink
  Color(0xFF29B6F6), // light blue
  Color(0xFFA1887F), // brown light
];

/// Для каждой привычки с [habitColorIsUnset] — свой цвет из палитры (порядок по `id`).
Map<String, Color> statsDefaultColorByHabitId(Iterable<Habit> habits) {
  final defaults = habits.where((h) => habitColorIsUnset(h.color)).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final map = <String, Color>{};
  for (var i = 0; i < defaults.length; i++) {
    map[defaults[i].id] = kStatsDefaultPalette[i % kStatsDefaultPalette.length];
  }
  return map;
}

/// Цвет для UI статистики: кастомный с карточки или назначенный из палитры.
Color statsHabitDisplayColor(Habit habit, Map<String, Color> defaultAssignments) {
  if (!habitColorIsUnset(habit.color)) return habit.color;
  return defaultAssignments[habit.id] ?? kStatsDefaultPalette.first;
}
