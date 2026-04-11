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
  ritual,   // good + binary — просто сделать/не сделать
  counter,  // good + counted — сделать N раз
  timer,    // good + timed — делать N минут
  temptation, // bad + binary — удержаться/сорваться
}

/// Цель привычки: без цели (бинарные) или целевое значение.
enum HabitGoalKind {
  noGoal,
  target,  // число для counter/timer
}

/// Снимок полей привычки для дней до [Habit.rulesEffectiveFrom].
class HabitPriorRules {
  const HabitPriorRules({
    required this.name,
    required this.direction,
    required this.measurement,
    required this.goal,
    required this.color,
    this.unit,
    this.repeatDays = const [],
    this.icon,
  });

  final String name;
  final HabitDirection direction;
  final HabitMeasurement measurement;
  final HabitGoal goal;
  final Color color;
  final String? unit;
  final List<int> repeatDays;
  final IconData? icon;

  static HabitPriorRules fromHabit(Habit h) => HabitPriorRules(
        name: h.name,
        direction: h.direction,
        measurement: h.measurement,
        goal: h.goal,
        color: h.color,
        unit: h.unit,
        repeatDays: List<int>.from(h.repeatDays),
        icon: h.icon,
      );

  /// Подставляет сохранённые поля в [base], не трогая id, даты, версионирование.
  Habit applyTo(Habit base) {
    return base.copyWith(
      name: name,
      direction: direction,
      measurement: measurement,
      goal: goal,
      color: color,
      unit: unit,
      repeatDays: repeatDays,
      icon: icon,
    );
  }
}

class HabitGoal {
  const HabitGoal.noGoal() : kind = HabitGoalKind.noGoal, value = null;
  const HabitGoal.target(this.value) : kind = HabitGoalKind.target;

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
    this.rulesEffectiveFrom,
    this.priorRules,
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

  /// С какого календарного дня действуют текущие поля (цель, название, …).
  /// Для дней **строго раньше** этой даты отображается [priorRules].
  final DateTime? rulesEffectiveFrom;

  /// Параметры для дней до [rulesEffectiveFrom] (включительно «вчера» относительно неё).
  final HabitPriorRules? priorRules;

  /// Финальный тип привычки по направлению и измерению.
  /// Для bad + counted/timed лимиты убраны — приводим к temptation (binary-like).
  HabitType get type {
    switch (direction) {
      case HabitDirection.good:
        switch (measurement) {
          case HabitMeasurement.binary: return HabitType.ritual;
          case HabitMeasurement.counted: return HabitType.counter;
          case HabitMeasurement.timed: return HabitType.timer;
        }
      case HabitDirection.bad:
        return HabitType.temptation;
    }
  }

  bool get isGoodHabit => direction == HabitDirection.good;

  /// Параметры привычки, актуальные для календарного дня [day] (с учётом версий).
  Habit forDate(DateTime day) {
    final p = priorRules;
    final from = rulesEffectiveFrom;
    if (p == null || from == null) return this;
    final d = DateTime(day.year, day.month, day.day);
    final boundary = DateTime(from.year, from.month, from.day);
    if (!d.isBefore(boundary)) return this;
    return p.applyTo(this);
  }

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
    DateTime? rulesEffectiveFrom,
    HabitPriorRules? priorRules,
    bool clearRulesEffectiveFrom = false,
    bool clearPriorRules = false,
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
      rulesEffectiveFrom: clearRulesEffectiveFrom
          ? null
          : (rulesEffectiveFrom ?? this.rulesEffectiveFrom),
      priorRules: clearPriorRules ? null : (priorRules ?? this.priorRules),
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
