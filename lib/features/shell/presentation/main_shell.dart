import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/models/habit.dart';
import '../../../../core/models/habit_log.dart';
import '../../../../core/repositories/habit_logs_repository.dart';
import '../../../../core/repositories/habits_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../subscription/presentation/subscription_screen.dart';
import 'main_menu_content.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../assistant/presentation/assistant_screen.dart';
import 'add_habit_screen.dart';
import 'edit_habit_screen.dart';

/// Оболочка приложения: AppBar (настройки, поиск, подписка) + контент по вкладке + нижняя навигация.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.openAddMenuOnStart = false,
  });

  /// Если true — сразу после первого кадра открывает меню добавления (действие).
  final bool openAddMenuOnStart;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  StatsPeriod _statsPeriod = StatsPeriod.week;
  int _statsMotivationNonce = 0;
  int _recenterCalendarTrigger = 0;
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _isTodayVisibleInStrip = true;
  List<Habit> _habits = [];
  Map<String, HabitLog> _dayLogs = {};
  static final HabitsRepository _habitsRepository = HabitsRepository.instance;
  final HabitLogsRepository _logsRepository = HabitLogsRepository();
  bool _habitsLoaded = false;
  DateTime _lastToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _didOpenAddMenuOnStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.instance.logScreenView(screenName: 'main');
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

  bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _canEditHabitsForSelectedDate {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final selected =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    // Прошлые дни только просмотр; сегодня и будущее — можно менять шаблон привычки.
    return !selected.isBefore(today);
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

  Future<void> _openAddMenu() async {
    final canAddH = await SubscriptionService.canAddHabit(_habits);
    final canAddE = await SubscriptionService.canAddEvent(_habits);
    if (!canAddH && !canAddE) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously - mounted check above
      _showSubscriptionDialog(
        message: SubscriptionService.getLimitReachedMessage(false),
      );
      return;
    }

    final habit = await showAddHabitScreen(
      context,
      existingHabits: _habits,
      initialDate: _selectedDate,
    );
    if (habit != null && mounted) {
      setState(() => _habits = [habit, ..._habits]);
      await _habitsRepository.addHabit(habit);
      await NotificationService.instance.resyncHabitReminder(habit);
      AnalyticsService.instance.logHabitAdded(habitType: habit.isEvent ? 'event' : 'habit');
    }
  }

  bool _isOneTimeHabit(Habit h) {
    if (h.repeatDays.isNotEmpty) return false;
    final s = h.startDate;
    final e = h.endDate;
    if (s == null || e == null) return false;
    return _isSameCalendarDay(s, e);
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
      if (_isOneTimeHabit(updated)) {
        final anchor = DateTime(
          updated.startDate!.year,
          updated.startDate!.month,
          updated.startDate!.day,
        );
        await _logsRepository.removeLogsForHabitAfterDate(updated.id, anchor);
        await _loadLogsForSelectedDate();
      }
      await NotificationService.instance.resyncHabitReminder(updated);
    }
  }

  Future<void> _onReorderActive(int oldIndex, int newIndex) async {
    final dayHabits = _habits
        .where(
          (h) => h.forDate(_selectedDate).isScheduledForDate(_selectedDate),
        )
        .toList();
    var active = dayHabits.where((h) => h.isActive).toList();
    // Та же сортировка, что и в MainMenuContent: невыполненные сверху
    active = List.from(active)
      ..sort((a, b) {
        final aDone = _dayLogs[a.id]?.isCompleted == true;
        final bDone = _dayLogs[b.id]?.isCompleted == true;
        if (aDone == bDone) return 0;
        return aDone ? 1 : -1;
      });
    if (oldIndex < 0 || oldIndex >= active.length || newIndex < 0 || newIndex >= active.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = List<Habit>.from(active);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    final inactive = dayHabits.where((h) => !h.isActive).toList();
    final dayIds = dayHabits.map((h) => h.id).toSet();
    final otherHabits = _habits.where((h) => !dayIds.contains(h.id)).toList();
    final newHabits = [...reordered, ...inactive, ...otherHabits];
    if (mounted) setState(() => _habits = newHabits);
    await _habitsRepository.reorderHabits(newHabits);
  }

  void _showSubscriptionDialog({String? message}) {
    SubscriptionScreen.show(context, limitMessage: message);
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
        await _openAddMenu();
      });
    }

    final dayHabits = _habits
        .where(
          (h) => h.forDate(_selectedDate).isScheduledForDate(_selectedDate),
        )
        .toList();

    // IndexedStack = Stack: без явного expand дети с Column+Expanded не получают
    // конечную высоту — ломается вся оболочка (в т.ч. главная вкладка).
    final body = IndexedStack(
      index: _currentIndex,
      children: [
        SizedBox.expand(
          child: MainMenuContent(
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
            onAddPressed: _openAddMenu,
            onHabitTap:
                _canEditHabitsForSelectedDate ? _openEditHabit : null,
            onLog: _onLog,
            onReorderActive: _onReorderActive,
          ),
        ),
        SizedBox.expand(
          child: StatsScreen(
            habitsRepository: _habitsRepository,
            logsRepository: _logsRepository,
            motivationNonce: _statsMotivationNonce,
            period: _statsPeriod,
          ),
        ),
        const SizedBox.expand(
          child: AssistantScreen(),
        ),
      ],
    );

    final isMainMenu = _currentIndex == 0;
    const coffee = Color(0xFF6B5A4E);

    const appBarFill = Color(0xFFF7F2EC);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: appBarFill,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: _TopIconButton(
            icon: isMainMenu ? Icons.settings_outlined : Icons.arrow_back,
            tooltip: isMainMenu ? l.settingsTooltip : l.closeButton,
            onPressed: () {
              if (isMainMenu) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              } else {
                setState(() => _currentIndex = 0);
              }
            },
          ),
        ),
        title: Text(
          isMainMenu
              ? _formatMainTitle(_selectedDate)
              : (_currentIndex == 1 ? l.tabStats : l.tabAssistant),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: coffee.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: true,
        bottom: _currentIndex == 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(kStatsPeriodAppBarHeight),
                child: ColoredBox(
                  color: appBarFill,
                  child: StatsPeriodTabBar(
                    period: _statsPeriod,
                    onChanged: (p) => setState(() => _statsPeriod = p),
                  ),
                ),
              )
            : null,
        actions: [
          if (isMainMenu && !_isTodayVisibleInStrip)
            _TopIconButton(
              icon: Icons.today_outlined,
              tooltip: l.backToTodayTooltip,
              onPressed: () => setState(() => _recenterCalendarTrigger++),
            ),
          if (isMainMenu)
            _TopIconButton(
              icon: Icons.calendar_month_outlined,
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
            ),
          if (isMainMenu)
            _TopIconButton(
              icon: Icons.card_giftcard_outlined,
              tooltip: l.subscriptionTitle,
              onPressed: () => _showSubscriptionDialog(),
            )
          else
            // На других вкладках оставим визуально "тихо", без лишних экшенов.
            const SizedBox.shrink(),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Mainback.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: body,
      ),
      bottomNavigationBar: _WarmBottomNavBar(
        currentIndex: _currentIndex,
        tabStatsLabel: l.tabStats,
        tabAssistantLabel: l.tabAssistant,
        onStats: () => setState(() {
          if (_currentIndex != 1) _statsMotivationNonce++;
          _currentIndex = 1;
        }),
        onAssistant: () {
          showDialog<void>(
            context: context,
            builder: (dialogContext) {
              final theme = Theme.of(dialogContext);
              final loc = AppLocalizations.of(dialogContext)!;
              // Один шаг: слева / сверху / снизу контента и зазор иконка → текст.
              const g = 20.0;
              const iconSlotH = 208.0;
              const coffeeTitle = Color(0xFF5A3E2B);
              const coffeeBody = Color(0xFF8A6A54);
              return AlertDialog(
                backgroundColor: const Color(0xFFF7F2EC),
                surfaceTintColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                content: Padding(
                  padding: const EdgeInsets.fromLTRB(g, g, g, g),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 112,
                        height: iconSlotH,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFE9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: const Offset(0, 4),
                          child: OverflowBox(
                            alignment: Alignment.center,
                            minWidth: 0,
                            minHeight: 0,
                            maxWidth: double.infinity,
                            maxHeight: double.infinity,
                            child: Image.asset(
                              'assets/icons/assistant.png',
                              width: 264,
                              height: 264,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: g),
                      Expanded(
                        child: SizedBox(
                          height: iconSlotH,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                loc.assistantInDevelopmentTitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: coffeeTitle,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: Text(
                                    loc.assistantInDevelopmentBody,
                                    textAlign: TextAlign.start,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: coffeeBody,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: Text(loc.assistantGotItButton),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        onAdd: _openAddMenu,
      ),
    );
  }

  String _formatMainTitle(DateTime selected) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(selected.year, selected.month, selected.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == -1) return 'Вчера';
    if (diff == 1) return 'Завтра';

    const months = <String>[
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    final m = (d.month >= 1 && d.month <= 12) ? months[d.month - 1] : '';
    return '${d.day} $m';
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Тёплый "кофейный" тон под общий визуал.
    const coffee = Color(0xFF6B5A4E);
    final fg = coffee.withValues(alpha: 0.92);
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onPressed,
          radius: 22,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: fg, size: 22),
          ),
        ),
      ),
    );
  }
}

class _WarmBottomNavBar extends StatelessWidget {
  const _WarmBottomNavBar({
    required this.currentIndex,
    required this.tabStatsLabel,
    required this.tabAssistantLabel,
    required this.onStats,
    required this.onAdd,
    required this.onAssistant,
  });

  final int currentIndex;
  final String tabStatsLabel;
  final String tabAssistantLabel;
  final VoidCallback onStats;
  final VoidCallback onAdd;
  final VoidCallback onAssistant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = MediaQuery.paddingOf(context).bottom;
    const coffee = Color(0xFF6B5A4E);
    final activeColor = coffee.withValues(alpha: 0.92);

    Widget navItem({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      final color = activeColor;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    const barChrome = Color(0xFFF7F2EC);

    return Material(
      color: barChrome,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + (pad > 0 ? 0 : 6)),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
            // Пилюля поверх глухой полосы на всю ширину слота bottomNavigationBar.
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: barChrome,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: navItem(
                      icon: Icons.bar_chart,
                      label: tabStatsLabel,
                      onTap: onStats,
                    ),
                  ),
                  const SizedBox(width: 64), // место под центральную "+"
                  Expanded(
                    child: navItem(
                      icon: Icons.smart_toy,
                      label: tabAssistantLabel,
                      onTap: onAssistant,
                    ),
                  ),
                ],
              ),
            ),
            // Центральная "+" кнопка — над пилюлей
            Positioned(
              bottom: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: InkResponse(
                  onTap: onAdd,
                  radius: 34,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(
                            Colors.white,
                            theme.colorScheme.primary,
                            0.35,
                          )!,
                          theme.colorScheme.primary,
                          Color.lerp(
                            theme.colorScheme.primary,
                            Colors.black,
                            0.10,
                          )!,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 3,
                      ),
                      boxShadow: [
                        // Нижняя тень
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Спекулярный блик сверху для "объёма"
                        Positioned(
                          top: 12,
                          left: 16,
                          child: Container(
                            width: 20,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.12),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.add,
                          size: 34,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ],
                    ),
                  ),
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
