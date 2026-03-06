import 'package:flutter/material.dart';

import '../models/habit.dart';

enum TemplateKind { habit, event }

class CatalogLimits {
  const CatalogLimits({
    required this.maxHabits,
    required this.maxEvents,
  });

  final int maxHabits;
  final int maxEvents;

  static CatalogLimits fromJson(Map<String, Object?> json) {
    return CatalogLimits(
      maxHabits: (json['maxHabits'] as num).toInt(),
      maxEvents: (json['maxEvents'] as num).toInt(),
    );
  }
}

class HabitTemplateGoal {
  const HabitTemplateGoal({required this.kind, this.value});

  final HabitGoalKind kind;
  final double? value;

  HabitGoal toHabitGoal() {
    return switch (kind) {
      HabitGoalKind.noGoal => const HabitGoal.noGoal(),
      HabitGoalKind.target => HabitGoal.target(value ?? 0),
      HabitGoalKind.limit => HabitGoal.limit(value ?? 0),
    };
  }

  static HabitTemplateGoal fromJson(Map<String, Object?> json) {
    final kindStr = json['kind'] as String;
    final kind = switch (kindStr) {
      'noGoal' => HabitGoalKind.noGoal,
      'target' => HabitGoalKind.target,
      'limit' => HabitGoalKind.limit,
      _ => throw FormatException('Unknown goal kind: $kindStr'),
    };
    final v = json['value'];
    return HabitTemplateGoal(
      kind: kind,
      value: v == null ? null : (v as num).toDouble(),
    );
  }
}

class HabitTemplate {
  const HabitTemplate({
    required this.templateId,
    required this.kind,
    required this.name,
    required this.direction,
    required this.measurement,
    required this.goal,
    required this.colorKey,
    required this.iconKey,
    required this.unit,
    required this.repeatDays,
    required this.defaultReminder,
    this.durationDays,
    this.isBase = false,
  });

  final String templateId;
  final TemplateKind kind;
  final String name;
  final HabitDirection direction;
  final HabitMeasurement measurement;
  final HabitTemplateGoal goal;
  final String colorKey;
  final String? iconKey;
  final String? unit;
  final List<int> repeatDays;
  final TimeOfDay? defaultReminder;
  /// Длительность базовой программы в днях (если null — бессрочная).
  final int? durationDays;
  /// Является ли шаблон базовым (для автодобавления при онбординге).
  final bool isBase;

  bool get isEvent => kind == TemplateKind.event;

  Habit createInstance({
    required String instanceId,
    required Color color,
    IconData? icon,
    DateTime? startDate,
    DateTime? endDate,
    String? templateId,
  }) {
    return Habit(
      id: instanceId,
      name: name,
      direction: direction,
      measurement: measurement,
      goal: goal.toHabitGoal(),
      color: color,
      icon: icon,
      unit: unit,
      repeatDays: repeatDays,
      reminder: defaultReminder,
      startDate: startDate,
      endDate: endDate,
      isEvent: isEvent,
      templateId: templateId ?? this.templateId,
    );
  }

  static HabitTemplate fromJson(Map<String, Object?> json) {
    final kindStr = json['kind'] as String;
    final kind = switch (kindStr) {
      'habit' => TemplateKind.habit,
      'event' => TemplateKind.event,
      _ => throw FormatException('Unknown template kind: $kindStr'),
    };

    HabitDirection parseDirection(String s) => switch (s) {
          'good' => HabitDirection.good,
          'bad' => HabitDirection.bad,
          _ => throw FormatException('Unknown direction: $s'),
        };

    HabitMeasurement parseMeasurement(String s) => switch (s) {
          'binary' => HabitMeasurement.binary,
          'counted' => HabitMeasurement.counted,
          'timed' => HabitMeasurement.timed,
          _ => throw FormatException('Unknown measurement: $s'),
        };

    final reminderRaw = json['defaultReminder'];
    TimeOfDay? reminder;
    if (reminderRaw is String && reminderRaw.contains(':')) {
      final parts = reminderRaw.split(':');
      reminder = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return HabitTemplate(
      templateId: json['templateId'] as String,
      kind: kind,
      name: json['name'] as String,
      direction: parseDirection(json['direction'] as String),
      measurement: parseMeasurement(json['measurement'] as String),
      goal: HabitTemplateGoal.fromJson(
        (json['goal'] as Map).cast<String, Object?>(),
      ),
      unit: json['unit'] as String?,
      colorKey: json['color'] as String,
      iconKey: json['icon'] as String?,
      repeatDays: ((json['repeatDays'] as List?) ?? const <Object?>[])
          .map((e) => (e as num).toInt())
          .toList(growable: false),
      defaultReminder: reminder,
      durationDays: (json['durationDays'] as num?)?.toInt(),
      isBase: json['isBase'] == true,
    );
  }
}

