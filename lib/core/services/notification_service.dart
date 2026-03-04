import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Сервис локальных напоминаний по привычкам.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _enabled = true;

  static const _prefsNotificationsKey = 'notifications_enabled';

  Future<void> init() async {
    if (_initialized) return;

    // На десктопе (Windows и др.) локальные уведомления пока не настраиваем:
    // они нужны только для Android-сборки.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _initialized = false;
      return;
    }

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(settings: initSettings);

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsNotificationsKey) ?? true;

    _initialized = true;
  }

  int _notificationIdForHabit(Habit habit) => habit.id.hashCode;

  Future<void> cancelForHabit(Habit habit) async {
    if (!_initialized) return;
    await _plugin.cancel(id: _notificationIdForHabit(habit));
  }

  /// Создаёт / обновляет ежедневное напоминание по [habit.reminder].
  /// Пока без учёта дней недели — просто каждый день в указанное время.
  Future<void> scheduleForHabit(Habit habit) async {
    if (!_initialized || !_enabled) return;
    final reminder = habit.reminder;
    if (reminder == null) return;

    final id = _notificationIdForHabit(habit);

    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Напоминания о привычках',
      channelDescription: 'Локальные напоминания по расписанию привычек',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final details = NotificationDetails(android: androidDetails);

    final now = TimeOfDay.now();

    // Если время ещё сегодня не прошло — покажем в этот же день, иначе со следующего.
    final todayHasPassed = reminder.hour < now.hour ||
        (reminder.hour == now.hour && reminder.minute <= now.minute);

    final scheduledDate = DateTime.now().add(
      Duration(days: todayHasPassed ? 1 : 0),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: habit.name,
      body: 'Пора: ${habit.name}',
      scheduledDate: tz.TZDateTime.from(
        DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          reminder.hour,
          reminder.minute,
        ),
        tz.local,
      ),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Пересоздаёт напоминание для привычки (или удаляет, если выключено).
  Future<void> resyncHabitReminder(Habit habit) async {
    await cancelForHabit(habit);
    if (_enabled && habit.reminder != null && habit.isActive) {
      await scheduleForHabit(habit);
    }
  }

  /// Включить/выключить все уведомления на устройстве.
  Future<void> setNotificationsEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsNotificationsKey, value);
    if (!_initialized) return;
    if (!value) {
      await _plugin.cancelAll();
    }
  }
}

