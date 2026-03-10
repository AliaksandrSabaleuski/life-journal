import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../catalog/color_registry.dart';
import '../catalog/icon_registry.dart';
import '../models/habit.dart';

const _key = 'habits_v1';

/// Сериализация и сохранение привычек в SharedPreferences.
class HabitsPersistence {
  static Future<List<Habit>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => _habitFromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final list = habits.map(_habitToMap).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  static Map<String, dynamic> _habitToMap(Habit h) {
    return {
      'id': h.id,
      'name': h.name,
      'direction': h.direction.index,
      'measurement': h.measurement.index,
      'goal': {'kind': h.goal.kind.index, 'value': h.goal.value},
      'color': h.color.value,
      'icon': h.icon != null
          ? {'codePoint': h.icon!.codePoint, 'fontFamily': h.icon!.fontFamily}
          : null,
      'unit': h.unit,
      'repeatDays': h.repeatDays,
      'isActive': h.isActive,
      'reminder': h.reminder != null
          ? {'hour': h.reminder!.hour, 'minute': h.reminder!.minute}
          : null,
      'startTime': h.startTime != null
          ? {'hour': h.startTime!.hour, 'minute': h.startTime!.minute}
          : null,
      'endTime': h.endTime != null
          ? {'hour': h.endTime!.hour, 'minute': h.endTime!.minute}
          : null,
      'startDate': h.startDate?.toIso8601String(),
      'endDate': h.endDate?.toIso8601String(),
      'isEvent': h.isEvent,
      'templateId': h.templateId,
    };
  }

  static Habit _habitFromMap(Map<String, dynamic> m) {
    final goalMap = m['goal'] as Map<String, dynamic>?;
    HabitGoal goal = const HabitGoal.noGoal();
    if (goalMap != null) {
      final kindIdx = goalMap['kind'] as int? ?? 0;
      final val = goalMap['value'] as num?;
      // Миграция: старый limit (индекс 2) — приводим к target
      final kind = kindIdx >= 2 ? HabitGoalKind.target : HabitGoalKind.values[kindIdx];
      goal = switch (kind) {
        HabitGoalKind.noGoal => const HabitGoal.noGoal(),
        HabitGoalKind.target => HabitGoal.target(val?.toDouble() ?? 1.0),
      };
    }

    IconData? icon;
    final iconMap = m['icon'] as Map<String, dynamic>?;
    if (iconMap != null) {
      final codePoint = iconMap['codePoint'] as int?;
      if (codePoint != null) {
        icon = IconData(
          codePoint,
          fontFamily: iconMap['fontFamily'] as String? ?? 'MaterialIcons',
        );
      }
    }

    TimeOfDay? reminder;
    final remMap = m['reminder'] as Map<String, dynamic>?;
    if (remMap != null) {
      reminder = TimeOfDay(
        hour: remMap['hour'] as int? ?? 0,
        minute: remMap['minute'] as int? ?? 0,
      );
    }

    TimeOfDay? startTime;
    final stMap = m['startTime'] as Map<String, dynamic>?;
    if (stMap != null) {
      startTime = TimeOfDay(
        hour: stMap['hour'] as int? ?? 0,
        minute: stMap['minute'] as int? ?? 0,
      );
    }

    TimeOfDay? endTime;
    final etMap = m['endTime'] as Map<String, dynamic>?;
    if (etMap != null) {
      endTime = TimeOfDay(
        hour: etMap['hour'] as int? ?? 0,
        minute: etMap['minute'] as int? ?? 0,
      );
    }

    DateTime? startDate;
    final sd = m['startDate'] as String?;
    if (sd != null) startDate = DateTime.tryParse(sd);

    DateTime? endDate;
    final ed = m['endDate'] as String?;
    if (ed != null) endDate = DateTime.tryParse(ed);

    final colorVal = m['color'] as int? ?? 0xFF607D8B;
    final color = Color(colorVal);

    final repeatDaysRaw = m['repeatDays'];
    List<int> repeatDays = const [];
    if (repeatDaysRaw is List) {
      repeatDays = repeatDaysRaw.map((e) => (e as num).toInt()).toList();
    }

    return Habit(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      direction: HabitDirection.values[m['direction'] as int? ?? 0],
      measurement: HabitMeasurement.values[m['measurement'] as int? ?? 0],
      goal: goal,
      color: color,
      icon: icon,
      unit: m['unit'] as String?,
      repeatDays: repeatDays,
      isActive: m['isActive'] as bool? ?? true,
      reminder: reminder,
      startTime: startTime,
      endTime: endTime,
      startDate: startDate,
      endDate: endDate,
      isEvent: m['isEvent'] as bool? ?? false,
      templateId: m['templateId'] as String?,
    );
  }
}
