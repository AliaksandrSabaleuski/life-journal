import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_log.dart';

const _key = 'habit_logs_v1';

/// Сериализация и сохранение логов в SharedPreferences.
class HabitLogsPersistence {
  static Future<List<HabitLog>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => _logFromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<HabitLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final list = logs.map(_logToMap).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  static Map<String, dynamic> _logToMap(HabitLog l) {
    return {
      'id': l.id,
      'habitId': l.habitId,
      'date': l.date.toIso8601String(),
      'value': l.value,
      'isCompleted': l.isCompleted,
    };
  }

  static HabitLog _logFromMap(Map<String, dynamic> m) {
    final dateStr = m['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    return HabitLog(
      id: m['id'] as String? ?? '',
      habitId: m['habitId'] as String? ?? '',
      date: date ?? DateTime.now(),
      value: (m['value'] as num?)?.toDouble(),
      isCompleted: m['isCompleted'] as bool?,
    );
  }
}
