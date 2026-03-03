import 'package:flutter/material.dart';

/// Одноразовое событие/запись за день.
class DayEvent {
  const DayEvent({
    required this.id,
    required this.title,
    required this.date,
    this.isDone = false,
  });

  final String id;
  final String title;
  final DateTime date;
  final bool isDone;

  /// Дата без времени.
  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  DayEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    bool? isDone,
  }) {
    return DayEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      isDone: isDone ?? this.isDone,
    );
  }
}

