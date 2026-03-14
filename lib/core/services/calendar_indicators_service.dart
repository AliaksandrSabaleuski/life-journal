import 'package:flutter/material.dart';

import '../models/habit.dart';

/// Сервис, который кэширует цвета индикаторов по датам для календаря.
class CalendarIndicatorsService {
  CalendarIndicatorsService(this._habits);

  final List<Habit> _habits;

  /// Кэш: dateOnly -> цвета для точек.
  final Map<DateTime, List<Color>> _cache = <DateTime, List<Color>>{};

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Предварительно прогревает кэш для диапазона дат.
  Future<void> preloadRange(DateTime start, DateTime end) async {
    var d = _dateOnly(start);
    final last = _dateOnly(end);
    while (!d.isAfter(last)) {
      dotsFor(d);
      d = d.add(const Duration(days: 1));
    }
  }

  /// Возвращает цвета для индикаторов в указанную дату.
  /// Если в кэше ещё нет — считает и сохраняет.
  /// Порядок маркеров фиксирован по id, не зависит от сортировки списка карточек.
  List<Color> dotsFor(DateTime date) {
    final key = _dateOnly(date);
    final existing = _cache[key];
    if (existing != null) return existing;

    final sorted = List<Habit>.from(_habits)
      ..sort((a, b) => a.id.compareTo(b.id));
    final result = <Color>[];
    for (final h in sorted) {
      if (!h.isScheduledForDate(key)) continue;
      result.add(h.color);
    }
    _cache[key] = result;
    return result;
  }
}

