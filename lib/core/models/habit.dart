import 'package:flutter/material.dart';

/// Направление привычки: внедряем хорошую или избавляемся от плохой.
enum HabitDirection {
  good,
  bad,
}

/// Тип измерения: бинарное (да/нет), по счётчику или по времени.
enum HabitMeasurement {
  binary,
  counted,
  timed,
}

/// Финальный тип привычки (вычисляется из direction + measurement).
enum HabitType {
  ritual,          // good + binary — просто сделать/не сделать
  counter,          // good + counted — сделать N раз
  timer,            // good + timed — делать N минут
  temptation,       // bad + binary — удержаться/сорваться
  limiter,          // bad + counted — не превысить N раз
  durationLimiter,  // bad + timed — не больше N минут
}

/// Цель привычки: без цели (бинарные), целевое значение или лимит.
enum HabitGoalKind {
  noGoal,
  target,  // число для counter/timer
  limit,   // число для limiter/durationLimiter
}

class HabitGoal {
  const HabitGoal.noGoal() : kind = HabitGoalKind.noGoal, value = null;
  const HabitGoal.target(this.value) : kind = HabitGoalKind.target;
  const HabitGoal.limit(this.value) : kind = HabitGoalKind.limit;

  final HabitGoalKind kind;
  final double? value;
}

/// Основная модель привычки.
class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.direction,
    required this.measurement,
    required this.goal,
    required this.color,
    this.icon,
    this.unit,
    this.repeatDays = const [],
    this.isActive = true,
    this.reminder,
    this.startTime,
    this.endTime,
    this.startDate,
    this.endDate,
    this.isEvent = false,
    this.templateId,
  });

  final String id;
  final String name;
  final HabitDirection direction;
  final HabitMeasurement measurement;
  final HabitGoal goal;
  final Color color;
  final IconData? icon;
  /// Единица измерения: "раз", "мин", "шт", "км" и т.д.
  final String? unit;
  /// Дни недели (1–7). Пустой = каждый день или настраивается позже.
  final List<int> repeatDays;
  final bool isActive;
  final TimeOfDay? reminder;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  /// Дата начала действия привычки (включительно). Если null — с самого начала.
  final DateTime? startDate;
  /// Дата окончания действия привычки (включительно). Если null — без окончания.
  final DateTime? endDate;

  /// Является ли запись событием (для вкладки «События»), а не обычной привычкой.
  final bool isEvent;

  /// ID шаблона каталога, если привычка создана из преднастроенного.
  final String? templateId;

  /// Финальный тип привычки по направлению и измерению.
  HabitType get type {
    switch (direction) {
      case HabitDirection.good:
        switch (measurement) {
          case HabitMeasurement.binary: return HabitType.ritual;
          case HabitMeasurement.counted: return HabitType.counter;
          case HabitMeasurement.timed: return HabitType.timer;
        }
      case HabitDirection.bad:
        switch (measurement) {
          case HabitMeasurement.binary: return HabitType.temptation;
          case HabitMeasurement.counted: return HabitType.limiter;
          case HabitMeasurement.timed: return HabitType.durationLimiter;
        }
    }
  }

  bool get isGoodHabit => direction == HabitDirection.good;

  /// Нужен ли шаг «Цель» при создании (для counted/timed).
  bool get needsGoalValue =>
      measurement == HabitMeasurement.counted || measurement == HabitMeasurement.timed;

  Habit copyWith({
    String? id,
    String? name,
    HabitDirection? direction,
    HabitMeasurement? measurement,
    HabitGoal? goal,
    Color? color,
    IconData? icon,
    String? unit,
    List<int>? repeatDays,
    bool? isActive,
    TimeOfDay? reminder,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? startDate,
    DateTime? endDate,
    bool? isEvent,
    String? templateId,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      direction: direction ?? this.direction,
      measurement: measurement ?? this.measurement,
      goal: goal ?? this.goal,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      unit: unit ?? this.unit,
      repeatDays: repeatDays ?? List<int>.from(this.repeatDays),
      isActive: isActive ?? this.isActive,
      reminder: reminder ?? this.reminder,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isEvent: isEvent ?? this.isEvent,
      templateId: templateId ?? this.templateId,
    );
  }

  /// Должна ли привычка отображаться в указанный день.
  bool isScheduledForDate(DateTime date) {
    if (!isActive) return false;
    final d = DateTime(date.year, date.month, date.day);

    if (startDate != null) {
      final s = DateTime(startDate!.year, startDate!.month, startDate!.day);
      if (d.isBefore(s)) return false;
    }

    if (endDate != null) {
      final e = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (d.isAfter(e)) return false;
    }

    if (repeatDays.isNotEmpty && !repeatDays.contains(d.weekday)) {
      return false;
    }

    return true;
  }
}
