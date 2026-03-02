import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/habit.dart';
import '../../../../core/models/habit_log.dart';
import '../../../../core/repositories/habit_logs_repository.dart';
import '../../../../core/repositories/habits_repository.dart';
import '../../../../l10n/app_localizations.dart';
import 'main_menu_content.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../settings/presentation/settings_screen.dart';

/// Оболочка приложения: AppBar (настройки, поиск, подписка) + контент по вкладке + нижняя навигация.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _recenterCalendarTrigger = 0;
  bool _isTodayVisibleInStrip = true;
  List<Habit> _habits = [];
  Map<String, HabitLog> _todayLogs = {};
  final HabitsRepository _habitsRepository = HabitsRepository();
  final HabitLogsRepository _logsRepository = HabitLogsRepository();
  bool _habitsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final list = await _habitsRepository.getHabits();
    if (mounted) {
      setState(() => _habits = list);
      _habitsLoaded = true;
      _loadTodayLogs();
    }
  }

  Future<void> _loadTodayLogs() async {
    final map = <String, HabitLog>{};
    for (final h in _habits) {
      final log = await _logsRepository.getTodayLog(h.id);
      if (log != null) map[h.id] = log;
    }
    if (mounted) setState(() => _todayLogs = map);
  }

  Future<void> _openAddHabit() async {
    final habit = await showAddHabitWizard(context);
    if (habit != null && mounted) {
      setState(() => _habits = [..._habits, habit]);
    }
  }

  Future<void> _openEditHabit(Habit habit) async {
    final updated = await showEditHabitDialog(context, habit);
    if (updated != null && mounted) {
      setState(() {
        _habits = _habits.map((h) => h.id == updated.id ? updated : h).toList();
      });
    }
  }

  Future<void> _onLog(HabitLog log) async {
    await _logsRepository.updateOrAddLog(log);
    if (mounted) {
      setState(() => _todayLogs[log.habitId] = log);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final body = IndexedStack(
      index: _currentIndex,
      children: [
        MainMenuContent(
          habits: _habits,
          todayLogs: _todayLogs,
          isLoading: !_habitsLoaded,
          isMainMenuVisible: _currentIndex == 0,
          recenterCalendarTrigger: _recenterCalendarTrigger,
          onTodayVisibilityInStripChanged: (visible) {
            if (mounted && _isTodayVisibleInStrip != visible) {
              setState(() => _isTodayVisibleInStrip = visible);
            }
          },
          onAddHabit: _openAddHabit,
          onHabitTap: _openEditHabit,
          onLog: _onLog,
        ),
        const StatsScreen(),
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
                  onPressed: _openAddHabit,
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
