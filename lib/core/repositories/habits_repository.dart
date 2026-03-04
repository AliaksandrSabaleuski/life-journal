import 'package:flutter/material.dart';

import '../models/habit.dart';

/// Репозиторий привычек.
/// Пока хранит данные только в памяти. При первом обращении
/// заполняется мок‑данными для отладки.
class HabitsRepository {
  HabitsRepository();

  final List<Habit> _habits = [];
  bool _seeded = false;

  Future<List<Habit>> getHabits() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!_seeded) {
      _seedMockData();
      _seeded = true;
    }
    return List<Habit>.from(_habits);
  }

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index >= 0) {
      _habits[index] = habit;
    }
  }

  void _seedMockData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0);

    final weekEndToday = today;
    final weekStartToday = weekEndToday.subtract(const Duration(days: 6));

    final finishedWeekEnd = today.subtract(const Duration(days: 1));
    final finishedWeekStart = finishedWeekEnd.subtract(const Duration(days: 6));

    // 1) Привычка на месяц, сейчас середина.
    _habits.add(
      Habit(
        id: 'habit_month_water',
        name: 'Стакан воды (месяц)',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.counted,
        goal: const HabitGoal.target(5),
        color: Colors.lightBlueAccent,
        icon: Icons.water_drop,
        unit: 'стаканов',
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: true,
        startDate: monthStart,
        endDate: monthEnd,
        reminder: const TimeOfDay(hour: 9, minute: 0),
      ),
    );

    // 2) Привычка на неделю, активный последний день (неделя, где сегодня последний).
    _habits.add(
      Habit(
        id: 'habit_week_active',
        name: 'Прогулка (неделя, активна)',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.counted,
        goal: const HabitGoal.target(7),
        color: Colors.greenAccent,
        icon: Icons.directions_walk,
        unit: 'тыс. шагов',
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: true,
        startDate: weekStartToday,
        endDate: weekEndToday,
        reminder: const TimeOfDay(hour: 19, minute: 0),
      ),
    );

    // 3) Привычка на неделю, которая уже завершилась.
    _habits.add(
      Habit(
        id: 'habit_week_finished',
        name: 'Чтение (неделя, завершена)',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.counted,
        goal: const HabitGoal.target(20),
        color: Colors.deepPurpleAccent,
        icon: Icons.menu_book,
        unit: 'страниц',
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: false,
        startDate: finishedWeekStart,
        endDate: finishedWeekEnd,
      ),
    );

    // 4) Событие на месяц, уже завершилось (с разными результатами в логах).
    _habits.add(
      Habit(
        id: 'event_month_checkup',
        name: 'Проверка здоровья',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.binary,
        goal: const HabitGoal.noGoal(),
        color: Colors.orangeAccent,
        icon: Icons.medical_information,
        isEvent: true,
        repeatDays: const [],
        isActive: false,
        startDate: monthStart,
        endDate: today.subtract(const Duration(days: 7)),
      ),
    );

    // 5) Событие на месяц, с которого прошла неделя (ещё в прошлом, но ближе).
    _habits.add(
      Habit(
        id: 'event_month_meet',
        name: 'Встреча с друзьями',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.binary,
        goal: const HabitGoal.noGoal(),
        color: Colors.tealAccent,
        icon: Icons.group,
        isEvent: true,
        repeatDays: const [],
        isActive: false,
        startDate: today.subtract(const Duration(days: 30)),
        endDate: today.subtract(const Duration(days: 1)),
      ),
    );

    // 6) Таймер-привычка "Экран" — ограничение по времени на месяц.
    _habits.add(
      Habit(
        id: 'habit_timer_screen',
        name: 'Экран менее 1 часа',
        direction: HabitDirection.bad,
        measurement: HabitMeasurement.timed,
        goal: const HabitGoal.limit(60),
        color: Colors.redAccent,
        icon: Icons.phone_android,
        unit: 'мин',
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: true,
        startDate: monthStart,
        endDate: monthEnd,
      ),
    );

    // 7) Плохая привычка "Сигареты" — лимит по количеству, активна весь месяц.
    _habits.add(
      Habit(
        id: 'habit_bad_smoke',
        name: 'Сигареты',
        direction: HabitDirection.bad,
        measurement: HabitMeasurement.counted,
        goal: const HabitGoal.limit(5),
        color: Colors.brown,
        icon: Icons.smoking_rooms,
        unit: 'шт',
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: true,
        startDate: monthStart,
        endDate: monthEnd,
      ),
    );

    // 8) Разовое событие "Поездка" на прошлые выходные.
    final lastWeekend =
        today.subtract(Duration(days: (today.weekday % 7) + 1)); // пред. вс
    _habits.add(
      Habit(
        id: 'event_one_off_trip',
        name: 'Поездка за город',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.binary,
        goal: const HabitGoal.noGoal(),
        color: Colors.blueGrey,
        icon: Icons.park,
        isEvent: true,
        startDate: lastWeekend,
        endDate: lastWeekend,
        repeatDays: const [],
      ),
    );

    // 9) Еженедельное событие "Генеральная уборка".
    _habits.add(
      Habit(
        id: 'event_weekly_cleanup',
        name: 'Генеральная уборка',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.binary,
        goal: const HabitGoal.noGoal(),
        color: Colors.lightGreenAccent,
        icon: Icons.cleaning_services,
        isEvent: true,
        repeatDays: const [6], // суббота
        isActive: true,
        startDate: today.subtract(const Duration(days: 30)),
      ),
    );

    // 10) Утренняя зарядка — ежедневно, активна уже пару месяцев.
    _habits.add(
      Habit(
        id: 'habit_morning_exercise',
        name: 'Утренняя зарядка',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.timed,
        goal: const HabitGoal.target(15),
        color: Colors.orange,
        icon: Icons.fitness_center,
        unit: 'мин',
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: true,
        startDate: today.subtract(const Duration(days: 60)),
        endDate: today.add(const Duration(days: 60)),
        reminder: const TimeOfDay(hour: 7, minute: 30),
      ),
    );

    // 11) Медитация — будни, активна сейчас и ещё месяц вперёд.
    _habits.add(
      Habit(
        id: 'habit_evening_meditation',
        name: 'Медитация вечером',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.timed,
        goal: const HabitGoal.target(10),
        color: Colors.indigo,
        icon: Icons.self_improvement,
        unit: 'мин',
        repeatDays: const [1, 2, 3, 4, 5],
        isActive: true,
        startDate: today.subtract(const Duration(days: 10)),
        endDate: today.add(const Duration(days: 30)),
        reminder: const TimeOfDay(hour: 22, minute: 0),
      ),
    );

    // 12) Сон не позже 23:00 — привычка с лимитом, активна последние 3 месяца.
    _habits.add(
      Habit(
        id: 'habit_sleep_early',
        name: 'Ложиться до 23:00',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.binary,
        goal: const HabitGoal.noGoal(),
        color: Colors.deepPurple,
        icon: Icons.nights_stay,
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: true,
        startDate: today.subtract(const Duration(days: 90)),
      ),
    );

    // 13) Кофе — плохая привычка, лимит по кружкам, активна сейчас.
    _habits.add(
      Habit(
        id: 'habit_bad_coffee',
        name: 'Кофе',
        direction: HabitDirection.bad,
        measurement: HabitMeasurement.counted,
        goal: const HabitGoal.limit(3),
        color: Colors.brown.shade400,
        icon: Icons.local_cafe,
        unit: 'кружек',
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: true,
        startDate: today.subtract(const Duration(days: 30)),
        endDate: today.add(const Duration(days: 90)),
      ),
    );

    // 14) Йога по выходным — хорошая привычка, активна от месяца назад до месяца вперёд.
    _habits.add(
      Habit(
        id: 'habit_weekend_yoga',
        name: 'Йога по выходным',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.timed,
        goal: const HabitGoal.target(30),
        color: Colors.teal,
        icon: Icons.spa,
        unit: 'мин',
        repeatDays: const [6, 7],
        isActive: true,
        startDate: today.subtract(const Duration(days: 30)),
        endDate: today.add(const Duration(days: 30)),
      ),
    );

    // 15) Звонок родителям — еженедельное событие, уже завершённый период в прошлом.
    _habits.add(
      Habit(
        id: 'event_call_parents',
        name: 'Звонок родителям',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.binary,
        goal: const HabitGoal.noGoal(),
        color: Colors.lightBlue,
        icon: Icons.call,
        isEvent: true,
        repeatDays: const [7],
        isActive: false,
        startDate: today.subtract(const Duration(days: 120)),
        endDate: today.subtract(const Duration(days: 30)),
      ),
    );

    // 16) Курсы/обучение — долгий проект на год вперёд.
    _habits.add(
      Habit(
        id: 'habit_learning_course',
        name: 'Курсы / обучение',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.counted,
        goal: const HabitGoal.target(1),
        color: Colors.cyan,
        icon: Icons.school,
        unit: 'урок',
        repeatDays: const [1, 3, 5],
        isActive: true,
        startDate: today.subtract(const Duration(days: 15)),
        endDate: today.add(const Duration(days: 365)),
      ),
    );

    // 17) Раз в квартал — чек финансов, длинное прошлое и будущее.
    _habits.add(
      Habit(
        id: 'event_finance_review',
        name: 'Финансовый обзор',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.binary,
        goal: const HabitGoal.noGoal(),
        color: Colors.green.shade700,
        icon: Icons.account_balance_wallet,
        isEvent: true,
        repeatDays: const [],
        isActive: true,
        startDate: today.subtract(const Duration(days: 365)),
        endDate: today.add(const Duration(days: 365)),
      ),
    );

    // 18) Ритуал "Утренний дневник" — без окончания, начиная с прошлого месяца.
    _habits.add(
      Habit(
        id: 'ritual_morning_journal',
        name: 'Утренний дневник',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.binary,
        goal: const HabitGoal.noGoal(),
        color: Colors.amber,
        icon: Icons.book,
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: true,
        startDate: today.subtract(const Duration(days: 30)),
      ),
    );

    // 19) Ритуал "Вечерний обзор дня" — только будни, начнётся через неделю.
    _habits.add(
      Habit(
        id: 'ritual_evening_review',
        name: 'Вечерний обзор дня',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.binary,
        goal: const HabitGoal.noGoal(),
        color: Colors.pinkAccent,
        icon: Icons.checklist,
        repeatDays: const [1, 2, 3, 4, 5],
        isActive: true,
        startDate: today.add(const Duration(days: 7)),
        endDate: today.add(const Duration(days: 120)),
      ),
    );

    // 20) Будущее событие "Сдача анализов" — в следующем месяце.
    _habits.add(
      Habit(
        id: 'event_future_tests',
        name: 'Сдача анализов',
        direction: HabitDirection.good,
        measurement: HabitMeasurement.binary,
        goal: const HabitGoal.noGoal(),
        color: Colors.redAccent.shade100,
        icon: Icons.biotech,
        isEvent: true,
        repeatDays: const [],
        isActive: true,
        startDate: today.add(const Duration(days: 20)),
        endDate: today.add(const Duration(days: 50)),
      ),
    );
  }
}
