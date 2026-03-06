import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/habit.dart';
import '../../../../core/models/habit_log.dart';
import '../../../../core/repositories/habit_logs_repository.dart';
import '../../../../core/repositories/habits_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/notification_service.dart';
import 'main_menu_content.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../settings/presentation/settings_screen.dart';

/// Оболочка приложения: AppBar (настройки, поиск, подписка) + контент по вкладке + нижняя навигация.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.openAddMenuOnStart = false,
  });

  /// Если true — сразу после первого кадра открывает меню добавления (привычка/событие).
  final bool openAddMenuOnStart;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _recenterCalendarTrigger = 0;
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _isTodayVisibleInStrip = true;
  List<Habit> _habits = [];
  Map<String, HabitLog> _dayLogs = {};
  static final HabitsRepository _habitsRepository = HabitsRepository.instance;
  final HabitLogsRepository _logsRepository = HabitLogsRepository();
  bool _habitsLoaded = false;
  MainListTab _mainTab = MainListTab.events;
  DateTime _lastToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _didOpenAddMenuOnStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHabits();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleDateRolloverIfNeeded();
    }
  }

  Future<void> _handleDateRolloverIfNeeded() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today.isAtSameMomentAs(_lastToday)) return;
    final oldToday = _lastToday;
    _lastToday = today;

    if (_habitsLoaded) {
      await _logsRepository.finalizePastDays(_habits, now: now);
    }
    if (!mounted) return;

    setState(() {
      // Если пользователь смотрел «сегодня», переносим на новый день.
      if (_selectedDate.year == oldToday.year &&
          _selectedDate.month == oldToday.month &&
          _selectedDate.day == oldToday.day) {
        _selectedDate = today;
        _recenterCalendarTrigger++;
      }
    });
    await _loadLogsForSelectedDate();
  }

  Future<void> _loadHabits() async {
    final list = await _habitsRepository.getHabits();
    if (mounted) {
      setState(() => _habits = list);
      _habitsLoaded = true;
      await _logsRepository.finalizePastDays(_habits);
      _loadLogsForSelectedDate();
    }
  }

  Future<void> _loadLogsForSelectedDate() async {
    // Перед загрузкой логов гарантируем, что все прошедшие дни закрыты.
    // Это важно, когда пользователь листает календарь назад.
    if (_habitsLoaded) {
      await _logsRepository.finalizePastDays(_habits);
    }
    final map = <String, HabitLog>{};
    for (final h in _habits) {
      final log = await _logsRepository.getLogForDate(h.id, _selectedDate);
      if (log != null) map[h.id] = log;
    }
    if (mounted) setState(() => _dayLogs = map);
  }

  Future<void> _openAddHabit() async {
    final habit = await showAddHabitWizard(
      context,
      existingHabits: _habits,
      initialDate: _selectedDate,
    );
    if (habit != null && mounted) {
      setState(() => _habits = [..._habits, habit]);
      await _habitsRepository.addHabit(habit);
      await NotificationService.instance.resyncHabitReminder(habit);
    }
  }

  Future<void> _openAddEvent() async {
    final habit = await showAddHabitWizard(
      context,
      existingHabits: _habits,
      initialDate: _selectedDate,
      initialDirection: HabitDirection.good,
      initialMeasurement: HabitMeasurement.binary,
      isEventMode: true,
    );
    if (habit != null && mounted) {
      setState(() => _habits = [..._habits, habit]);
      await _habitsRepository.addHabit(habit);
      await NotificationService.instance.resyncHabitReminder(habit);
    }
  }

  Future<void> _openEditHabit(Habit habit) async {
    final updated = await showEditHabitDialog(
      context,
      habit,
      selectedDate: _selectedDate,
    );
    if (updated != null && mounted) {
      setState(() {
        _habits = _habits.map((h) => h.id == updated.id ? updated : h).toList();
      });
      await _habitsRepository.updateHabit(updated);
      await NotificationService.instance.resyncHabitReminder(updated);
    }
  }

  Future<void> _onLog(HabitLog log) async {
    await _logsRepository.updateOrAddLog(log);
    if (mounted) {
      // Обновляем только если лог относится к выбранному дню.
      final logDay = DateTime(log.date.year, log.date.month, log.date.day);
      if (logDay.year == _selectedDate.year &&
          logDay.month == _selectedDate.month &&
          logDay.day == _selectedDate.day) {
        setState(() => _dayLogs[log.habitId] = log);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (widget.openAddMenuOnStart && !_didOpenAddMenuOnStart) {
      _didOpenAddMenuOnStart = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (_mainTab == MainListTab.events) {
          await _openAddEvent();
        } else {
          await _openAddHabit();
        }
      });
    }

    final dayHabits =
        _habits.where((h) => h.isScheduledForDate(_selectedDate)).toList();

    final body = IndexedStack(
      index: _currentIndex,
      children: [
        MainMenuContent(
          allHabits: _habits,
          habits: dayHabits,
          todayLogs: _dayLogs,
          isLoading: !_habitsLoaded,
          isMainMenuVisible: _currentIndex == 0,
          recenterCalendarTrigger: _recenterCalendarTrigger,
          selectedDate: _selectedDate,
          onSelectedDateChanged: (date) {
            if (!mounted) return;
            setState(() {
              _selectedDate = DateTime(date.year, date.month, date.day);
            });
            _loadLogsForSelectedDate();
          },
          onTodayVisibilityInStripChanged: (visible) {
            if (mounted && _isTodayVisibleInStrip != visible) {
              setState(() => _isTodayVisibleInStrip = visible);
            }
          },
          currentTab: _mainTab,
          onTabChanged: (tab) {
            if (!mounted) return;
            setState(() => _mainTab = tab);
          },
          onAddPressed: () {
            if (_mainTab == MainListTab.events) {
              _openAddEvent();
            } else {
              _openAddHabit();
            }
          },
          onHabitTap: _openEditHabit,
          onLog: _onLog,
        ),
        StatsScreen(
          habitsRepository: _habitsRepository,
          logsRepository: _logsRepository,
        ),
        const SettingsScreen(),
      ],
    );

    final isMainMenu = _currentIndex == 0;
    final now = DateTime.now();
    final monthYear = DateFormat.yMMMM().format(now);

    return Scaffold(
      appBar: AppBar(
        leading: isMainMenu
            ? IconButton(
                icon: const Icon(Icons.calendar_month_outlined),
                tooltip: l.tabCalendar,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: Text(l.tabCalendar),
                        ),
                        body: CalendarScreen(
                          selectedTabIndex: 1,
                          calendarTabIndex: 1,
                          habits: _habits,
                        ),
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(() => _recenterCalendarTrigger++);
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l.closeButton,
                onPressed: () => setState(() => _currentIndex = 0),
              ),
        title: Text(
          isMainMenu
              ? monthYear
              : (_currentIndex == 1 ? l.tabStats : l.settingsTitle),
        ),
        centerTitle: true,
        actions: [
          if (isMainMenu && !_isTodayVisibleInStrip)
            IconButton(
              icon: const Icon(Icons.today_outlined),
              tooltip: l.backToTodayTooltip,
              onPressed: () => setState(() => _recenterCalendarTrigger++),
            ),
          IconButton(
            icon: const Icon(Icons.card_giftcard_outlined),
            tooltip: l.subscriptionTitle,
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.subscriptionTitle),
                  content: Text(l.subscriptionBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l.closeButton),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _currentIndex == 1
                            ? Icons.bar_chart
                            : Icons.bar_chart_outlined,
                        color: _currentIndex == 1
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      Text(
                        l.tabStats,
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentIndex == 1
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () {
                    if (_mainTab == MainListTab.events) {
                      _openAddEvent();
                    } else {
                      _openAddHabit();
                    }
                  },
                  icon: const Icon(Icons.add),
                  iconSize: 32,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _currentIndex == 2
                            ? Icons.settings
                            : Icons.settings_outlined,
                        color: _currentIndex == 2
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      Text(
                        l.settingsTooltip,
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentIndex == 2
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
