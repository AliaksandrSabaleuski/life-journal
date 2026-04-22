import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TimerState {
  _TimerState({
    required this.habitId,
    required this.dayMs,
    required this.baseSeconds,
    this.startedAtMs,
  });

  final String habitId;
  final int dayMs;
  int baseSeconds;
  int? startedAtMs;

  bool get isRunning => startedAtMs != null;

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'dayMs': dayMs,
        'baseSeconds': baseSeconds,
        'startedAtMs': startedAtMs,
      };

  static _TimerState? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final habitId = raw['habitId'];
    final dayMs = raw['dayMs'];
    final baseSeconds = raw['baseSeconds'];
    if (habitId is! String || dayMs is! int || baseSeconds is! int) return null;
    final startedAtMs = raw['startedAtMs'];
    return _TimerState(
      habitId: habitId,
      dayMs: dayMs,
      baseSeconds: baseSeconds,
      startedAtMs: startedAtMs is int ? startedAtMs : null,
    );
  }
}

/// Глобальные активные таймеры (параллельные).
///
/// Идея: не "тикать" внутри каждой карточки, а вычислять прогресс по системному
/// времени (baseSeconds + (now - startedAt)).
///
/// Это позволяет таймеру продолжаться при смене вкладок/дней/экранов и
/// корректно восстанавливаться после пересоздания UI.
class ActiveTimerService extends ChangeNotifier {
  ActiveTimerService._();
  static final ActiveTimerService instance = ActiveTimerService._();

  static const _prefsKeyTimers = 'active_timer.timers.v2';
  static const _prefsKeyLegacyHabitId = 'active_timer.habitId';
  static const _prefsKeyLegacyDay = 'active_timer.dayMs';
  static const _prefsKeyLegacyStartedAt = 'active_timer.startedAtMs';
  static const _prefsKeyLegacyBaseSeconds = 'active_timer.baseSeconds';

  final Map<String, _TimerState> _timers = {};

  Timer? _tick;

  bool get hasAnyRunning => _timers.values.any((t) => t.isRunning);

  Iterable<_TimerState> get runningTimers sync* {
    for (final t in _timers.values) {
      if (t.isRunning) yield t;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _timers.clear();

    // v2
    final raw = prefs.getString(_prefsKeyTimers);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            final t = _TimerState.fromJson(e);
            if (t == null) continue;
            _timers[_key(t.habitId, t.dayMs)] = t;
          }
        }
      } catch (_) {
        // ignore broken payload
      }
    } else {
      // legacy (один таймер) -> миграция в v2
      final legacyHabitId = prefs.getString(_prefsKeyLegacyHabitId);
      final legacyDay = prefs.getInt(_prefsKeyLegacyDay);
      final legacyStartedAt = prefs.getInt(_prefsKeyLegacyStartedAt);
      final legacyBase = prefs.getInt(_prefsKeyLegacyBaseSeconds) ?? 0;
      if (legacyHabitId != null && legacyDay != null) {
        _timers[_key(legacyHabitId, legacyDay)] = _TimerState(
          habitId: legacyHabitId,
          dayMs: legacyDay,
          baseSeconds: legacyBase,
          startedAtMs: legacyStartedAt,
        );
      }
      // чистим legacy ключи, чтобы больше не мешали
      await prefs.remove(_prefsKeyLegacyHabitId);
      await prefs.remove(_prefsKeyLegacyDay);
      await prefs.remove(_prefsKeyLegacyStartedAt);
      await prefs.remove(_prefsKeyLegacyBaseSeconds);
      await _persist();
    }

    _ensureTickingIfNeeded();
    notifyListeners();
  }

  bool isRunningFor(String habitId, DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final k = _key(habitId, dayOnly.millisecondsSinceEpoch);
    final t = _timers[k];
    return t?.isRunning ?? false;
  }

  int currentElapsedSecondsFor(String habitId, DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final k = _key(habitId, dayOnly.millisecondsSinceEpoch);
    final t = _timers[k];
    if (t == null) return 0;
    if (!t.isRunning) return t.baseSeconds;
    final startedAt = t.startedAtMs!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final delta = ((now - startedAt) / 1000).floor();
    final out = t.baseSeconds + (delta < 0 ? 0 : delta);
    // защита от диких значений (24 часа)
    return out.clamp(0, 24 * 60 * 60);
  }

  /// Запускает таймер для [habitId] на календарный день [day].
  /// [baseSeconds] — уже накопленный прогресс (из лога).
  Future<void> start({
    required String habitId,
    required DateTime day,
    required int baseSeconds,
  }) async {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final dayMs = dayOnly.millisecondsSinceEpoch;
    final k = _key(habitId, dayMs);
    _timers[k] = _TimerState(
      habitId: habitId,
      dayMs: dayMs,
      baseSeconds: baseSeconds.clamp(0, 24 * 60 * 60),
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
    _ensureTickingIfNeeded();
    notifyListeners();
  }

  /// Останавливает таймер для [habitId]/[day], фиксируя текущее значение в baseSeconds.
  /// Возвращает накопленные секунды.
  Future<int> stopFor({
    required String habitId,
    required DateTime day,
  }) async {
    final seconds = currentElapsedSecondsFor(habitId, day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    final k = _key(habitId, dayOnly.millisecondsSinceEpoch);
    final t = _timers[k];
    if (t == null) return seconds;
    t.baseSeconds = seconds;
    t.startedAtMs = null;
    await _persist();
    _stopTicking();
    notifyListeners();
    return seconds;
  }

  /// Полный сброс состояния.
  Future<void> clear() async {
    _timers.clear();
    await _persist(clear: true);
    _stopTicking();
    notifyListeners();
  }

  Future<void> _persist({bool clear = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (clear) {
      await prefs.remove(_prefsKeyTimers);
      return;
    }
    final list = _timers.values.map((t) => t.toJson()).toList(growable: false);
    await prefs.setString(_prefsKeyTimers, jsonEncode(list));
  }

  void _ensureTickingIfNeeded() {
    if (!hasAnyRunning) return;
    _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
      // тик нужен только чтобы UI обновлялся
      notifyListeners();
    });
  }

  void _stopTicking() {
    _tick?.cancel();
    _tick = null;
  }

  static String _key(String habitId, int dayMs) => '$habitId|$dayMs';
}

