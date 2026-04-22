import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

import '../models/habit.dart';

/// Сервис локальных напоминаний по привычкам.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _enabled = true;

  static const _prefsNotificationsKey = 'notifications_enabled';
  static const _prefsLastOpenMsKey = 'engagement_last_open_ms';

  static const int _engagementIdDay1 = 910001;
  static const int _engagementIdDay3 = 910002;

  static const _engagementChannel = AndroidNotificationDetails(
    'engagement',
    'Возврат в приложение',
    channelDescription: 'Уведомления, если пользователь давно не заходил',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const List<String> _engagementBodies = [
    'Как прошёл ваш день без нашего обычного напоминания? 👀 Запишите свои успехи, пока они свежи в памяти.',
    'Тишина в эфире целые сутки. Надеемся, у вас всё хорошо! Зайдите отметить галочку, если всё в порядке.',
    'Ваша серия наблюдений прервалась! 🔥 Верните огонёк, сделав всего одно действие прямо сейчас.',
    'Вы были так близки к личному рекорду! Не останавливайтесь, сделайте маленький шаг к большой цели сегодня.',
    'Ваша статистика застыла на месте. ⏸️ Пора снова запустить механизм роста!',
    'Ваш дневник привычек ждёт пополнения. 📖 Что интересного случилось за этот день?',
  ];

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

  /// Вызывать на старте приложения: фиксирует "вход" и пересоздаёт
  /// уведомления «не заходил сутки» и «не заходил ещё 2 суток».
  Future<void> onAppOpened() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsLastOpenMsKey, now.millisecondsSinceEpoch);

    // Сбрасываем старые "реактивационные" уведомления и планируем заново.
    await _plugin.cancel(id: _engagementIdDay1);
    await _plugin.cancel(id: _engagementIdDay3);
    if (!_enabled) return;

    await _scheduleEngagementNotifications(from: now);
  }

  Future<void> _scheduleEngagementNotifications({required DateTime from}) async {
    // 1) Через 24 часа
    // 2) Если после него ещё 2 суток не заходил => через 72 часа от последнего входа
    final details = const NotificationDetails(android: _engagementChannel);
    final rng = Random();

    final when1 = tz.TZDateTime.from(from.add(const Duration(days: 1)), tz.local);
    final when3 = tz.TZDateTime.from(from.add(const Duration(days: 3)), tz.local);

    await _plugin.zonedSchedule(
      id: _engagementIdDay1,
      title: 'Мы скучаем',
      body: _engagementBodies[rng.nextInt(_engagementBodies.length)],
      scheduledDate: when1,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );

    await _plugin.zonedSchedule(
      id: _engagementIdDay3,
      title: 'Давно не виделись',
      body: _engagementBodies[rng.nextInt(_engagementBodies.length)],
      scheduledDate: when3,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  /// Запросить разрешение на уведомления (Android 13+).
  ///
  /// Возвращает:
  /// - `true/false` на Android, если платформа поддерживает запрос
  /// - `null` на остальных платформах (где мы не запрашиваем)
  Future<bool?> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    if (!_initialized) {
      await init();
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return android?.requestNotificationsPermission();
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

  /// DEV/QA: показать тестовое уведомление сразу.
  Future<void> showTestNow({
    String title = 'Тестовое уведомление',
    String body = 'Это тест. Проверь баннер/звук/тап.',
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (!_initialized) {
      await init();
    }
    if (!_initialized || !_enabled) return;

    const androidDetails = AndroidNotificationDetails(
      'dev_test',
      'Тестовые уведомления',
      channelDescription: 'Временный канал для тестов в дев-сборке',
      importance: Importance.high,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: 987654,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// DEV/QA: запланировать тестовое уведомление через [delay].
  Future<void> scheduleTestAfter(
    Duration delay, {
    String title = 'Тестовое уведомление (план)',
    String body = 'Должно прийти через несколько минут.',
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (!_initialized) {
      await init();
    }
    if (!_initialized || !_enabled) return;

    const androidDetails = AndroidNotificationDetails(
      'dev_test',
      'Тестовые уведомления',
      channelDescription: 'Временный канал для тестов в дев-сборке',
      importance: Importance.high,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails);

    final when = tz.TZDateTime.from(
      DateTime.now().add(delay),
      tz.local,
    );

    await _plugin.zonedSchedule(
      id: 987655,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }
}

