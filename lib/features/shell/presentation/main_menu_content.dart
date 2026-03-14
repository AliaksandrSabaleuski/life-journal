import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/habit.dart';
import '../../../../core/models/habit_log.dart';
import '../../../../core/widgets/habit_card.dart';
import '../../../../l10n/app_localizations.dart';
import 'add_habit_wizard.dart';
import 'edit_habit_dialog.dart';

/// Контент главной вкладки: календарная полоса + все записи (привычки и события) в одном списке.
class MainMenuContent extends StatelessWidget {
  const MainMenuContent({
    super.key,
    required this.allHabits,
    required this.habits,
    this.todayLogs = const {},
    this.isLoading = false,
    this.isMainMenuVisible = true,
    this.recenterCalendarTrigger = 0,
    required this.selectedDate,
    this.onSelectedDateChanged,
    this.onTodayVisibilityInStripChanged,
    this.onAddPressed,
    this.onHabitTap,
    this.onLog,
    this.onReorderActive,
  });

  /// Вызывается при перетаскивании карточки (oldIndex, newIndex в списке активных).
  final void Function(int oldIndex, int newIndex)? onReorderActive;

  /// Все привычки пользователя (нужны для индикаторов под календарём).
  final List<Habit> allHabits;

  /// Привычки, отфильтрованные под выбранный день (для списка ниже).
  final List<Habit> habits;
  final Map<String, HabitLog> todayLogs;
  final bool isLoading;
  final bool isMainMenuVisible;
  final int recenterCalendarTrigger;
  final DateTime selectedDate;
  final void Function(DateTime date)? onSelectedDateChanged;
  final void Function(bool visible)? onTodayVisibilityInStripChanged;
  final VoidCallback? onAddPressed;
  final void Function(Habit)? onHabitTap;
  final void Function(HabitLog)? onLog;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t0 = DateTime.now();

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final active = habits.where((h) => h.isActive).toList();
    final inactive = habits.where((h) => !h.isActive).toList();

    // Сортировка: невыполненные сверху, выполненные внизу (порядок внутри групп сохраняется)
    active.sort((a, b) {
      final aDone = todayLogs[a.id]?.isCompleted == true;
      final bDone = todayLogs[b.id]?.isCompleted == true;
      if (aDone == bDone) return 0;
      return aDone ? 1 : -1;
    });

    final bottomPadding = 80.0 + MediaQuery.paddingOf(context).bottom;
    final result = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalendarStripWithRecenter(
          isVisible: isMainMenuVisible,
          recenterTrigger: recenterCalendarTrigger,
          initialSelectedDate: selectedDate,
          habits: allHabits,
          onDateSelected: onSelectedDateChanged,
          onTodayVisibilityChanged: onTodayVisibilityInStripChanged,
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
            ),
            child: ListView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              children: _buildListSection(context, l, active, inactive),
            ),
          ),
        ),
      ],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ms = DateTime.now().difference(t0).inMilliseconds;
      debugPrint('[PERF] MAIN_MENU_BUILD date=$selectedDate ms=$ms');
    });
    return result;
  }

  List<Widget> _buildListSection(
    BuildContext context,
    AppLocalizations l,
    List<Habit> active,
    List<Habit> inactive,
  ) {
    debugPrint(
      '[PERF] LIST_SECTION active=${active.length} inactive=${inactive.length}',
    );

    if (active.isEmpty && inactive.isEmpty) {
      return [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l.noEventsForDay,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    return [
      _ReorderableList(
        habits: active,
        todayLogs: todayLogs,
        logDate: selectedDate,
        onHabitTap: onHabitTap,
        onLog: onLog,
        onReorder: onReorderActive,
      ),
      if (inactive.isNotEmpty) ...[
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Неактивные (позже — на календаре)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: inactive.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, index) {
            final habit = inactive[index];
            return HabitCard(
              habit: habit,
              todayLog: todayLogs[habit.id],
              logDate: selectedDate,
              onTap: onHabitTap != null ? () => onHabitTap!(habit) : null,
              onLog: onLog != null ? (log) => onLog!(log) : null,
            );
          },
        ),
      ],
    ];
  }

}

const _dayCellWidth = 52.0;

/// Обёртка календарной полосы (кнопка центрирования — в хедере, слева от календаря).
class _CalendarStripWithRecenter extends StatelessWidget {
  const _CalendarStripWithRecenter({
    required this.isVisible,
    required this.recenterTrigger,
    required this.initialSelectedDate,
    required this.habits,
    this.onDateSelected,
    this.onTodayVisibilityChanged,
  });

  final bool isVisible;
  final int recenterTrigger;
  final DateTime initialSelectedDate;
  final List<Habit> habits;
  final void Function(DateTime date)? onDateSelected;
  final void Function(bool visible)? onTodayVisibilityChanged;

  static const double _stripHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _stripHeight,
      child: _CalendarStrip(
        isVisible: isVisible,
        recenterTrigger: recenterTrigger,
        initialSelectedDate: initialSelectedDate,
        habits: habits,
        onDateSelected: onDateSelected,
        onTodayVisibilityChanged: onTodayVisibilityChanged,
      ),
    );
  }
}

/// Диапазон дат как в экране календаря: январь 2022 — декабрь 2036.
final DateTime _stripStartDate = DateTime(2022, 1, 1);
final DateTime _stripEndDate = DateTime(2036, 12, 31);

class _CalendarStrip extends StatefulWidget {
  const _CalendarStrip({
    required this.isVisible,
    required this.recenterTrigger,
    required this.initialSelectedDate,
    required this.habits,
    this.onDateSelected,
    this.onTodayVisibilityChanged,
  });

  final bool isVisible;
  final int recenterTrigger;
  final DateTime initialSelectedDate;
  final List<Habit> habits;
  final void Function(DateTime date)? onDateSelected;
  final void Function(bool visible)? onTodayVisibilityChanged;

  @override
  State<_CalendarStrip> createState() => _CalendarStripState();
}

class _ReorderableList extends StatefulWidget {
  const _ReorderableList({
    Key? key,
    required this.habits,
    required this.todayLogs,
    required this.logDate,
    this.onHabitTap,
    this.onLog,
    this.onReorder,
  }) : super(key: key);

  final List<Habit> habits;
  final Map<String, HabitLog> todayLogs;
  final DateTime logDate;
  final void Function(Habit)? onHabitTap;
  final void Function(HabitLog)? onLog;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  State<_ReorderableList> createState() => _ReorderableListState();
}

class _ReorderableListState extends State<_ReorderableList> {
  late List<Habit> _items;

  @override
  void initState() {
    super.initState();
    _items = List<Habit>.from(widget.habits);
  }

  @override
  void didUpdateWidget(covariant _ReorderableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.habits != widget.habits) {
      _items = List<Habit>.from(widget.habits);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canReorder = _items.length > 1 && widget.onReorder != null;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _items.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        final item = _items.removeAt(oldIndex);
        _items.insert(newIndex, item);
        widget.onReorder?.call(oldIndex, newIndex);
        setState(() {});
      },
      itemBuilder: (context, index) {
        final habit = _items[index];
        final card = HabitCard(
          habit: habit,
          todayLog: widget.todayLogs[habit.id],
          logDate: widget.logDate,
          onTap:
              widget.onHabitTap != null ? () => widget.onHabitTap!(habit) : null,
          onLog: widget.onLog != null ? (log) => widget.onLog!(log) : null,
        );
        return Column(
          key: ValueKey(habit.id),
          mainAxisSize: MainAxisSize.min,
          children: [
            canReorder
                ? ReorderableDragStartListener(
                    index: index,
                    child: card,
                  )
                : card,
            if (index < _items.length - 1) const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}

class _CalendarStripState extends State<_CalendarStrip> {
  late final ScrollController _scrollController;
  static final DateTime _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _selectedDate;

  static int get _totalDays =>
      _stripEndDate.difference(_stripStartDate).inDays + 1;

  static int get _todayIndex {
    if (_today.isBefore(_stripStartDate)) return 0;
    if (_today.isAfter(_stripEndDate)) return _totalDays - 1;
    return _today.difference(_stripStartDate).inDays;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Порядок маркеров фиксирован по id, не зависит от сортировки списка карточек.
  List<Color> _indicatorColorsFor(DateTime date, ThemeData theme) {
    final sorted = List<Habit>.from(widget.habits)
      ..sort((a, b) => a.id.compareTo(b.id));
    final result = <Color>[];
    for (final h in sorted) {
      if (!h.isActive) continue;
      if (!h.isScheduledForDate(date)) continue;
      result.add(h.color);
      if (result.length == 6) break;
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_notifyTodayVisibility);
    _selectedDate = DateTime(
      widget.initialSelectedDate.year,
      widget.initialSelectedDate.month,
      widget.initialSelectedDate.day,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday(animate: false));
  }

  @override
  void didUpdateWidget(covariant _CalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday(animate: true));
    } else if (widget.recenterTrigger != oldWidget.recenterTrigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday(animate: true));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_notifyTodayVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  void _notifyTodayVisibility() {
    widget.onTodayVisibilityChanged?.call(_isTodayInViewport());
  }

  bool _isTodayInViewport() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    const itemWidth = _dayCellWidth;
    final todayLeft = _todayIndex * itemWidth;
    final todayRight = todayLeft + itemWidth;
    final start = position.pixels;
    final end = position.pixels + position.viewportDimension;
    // Считаем, что «сегодня видно», только если вся ячейка полностью в пределах viewport.
    // Как только день хотя бы немного уезжает за край, считаем, что его «не видно»
    // и показываем кнопку «вернуться к сегодня».
    return todayLeft >= start && todayRight <= end;
  }

  void _scrollToToday({bool animate = false}) {
    if (!mounted) return;
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday(animate: animate));
      return;
    }
    final position = _scrollController.position;
    final viewportWidth = position.viewportDimension;
    if (viewportWidth <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday(animate: animate));
      return;
    }
    const itemWidth = _dayCellWidth;
    if (!_isSameDay(_selectedDate, _today)) {
      _selectedDate = _today;
      widget.onDateSelected?.call(_selectedDate);
      setState(() {});
    }
    final todayIndex = _todayIndex;
    final targetOffset = (todayIndex * itemWidth) + (itemWidth / 2) - (viewportWidth / 2);
    final clampedOffset = targetOffset.clamp(0.0, position.maxScrollExtent);
    if ((position.pixels - clampedOffset).abs() < 1.0) return;
    if (animate) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ).then((_) => _notifyTodayVisibility());
    } else {
      _scrollController.jumpTo(clampedOffset);
      _notifyTodayVisibility();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final weekdayShortFormat = DateFormat('E', locale.toString());
    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context);
    const sidePadding = 16.0;
    final paddingLeft = sidePadding + padding.left;
    final paddingRight = sidePadding + padding.right;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.fromLTRB(paddingLeft, 8, paddingRight, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 80,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: const {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemExtent: _dayCellWidth,
                    itemCount: _totalDays,
                    itemBuilder: (context, index) {
                      final date = _stripStartDate.add(Duration(days: index));
                      final isToday = _isSameDay(date, _today);
                      final isSelected = _isSameDay(date, _selectedDate);
                      final weekdayShort = weekdayShortFormat.format(date);
                      final bgColor =
                          isToday ? theme.colorScheme.primaryContainer : null;
                      final textColor = isToday
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface;
                      final dots = _indicatorColorsFor(date, theme);

                      return InkWell(
                        onTap: () {
                          final t0 = DateTime.now();
                          if (!_isSameDay(_selectedDate, date)) {
                            _selectedDate = date;
                            widget.onDateSelected?.call(date);
                            setState(() {});
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final ms = DateTime.now()
                                .difference(t0)
                                .inMilliseconds;
                            debugPrint(
                              '[PERF] STRIP_DAY_SELECT date=$date ms=$ms',
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              weekdayShort,
                              style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${date.day}',
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: isToday || isSelected
                                          ? FontWeight.w600
                                          : null,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                if (isSelected || isToday)
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.9),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            SizedBox(
                              height: 8,
                              child: Center(
                                child: dots.isNotEmpty
                                    ? Wrap(
                                        spacing: 2,
                                        runSpacing: 2,
                                        alignment: WrapAlignment.center,
                                        children: dots
                                            .map(
                                              (c) => Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: c,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Открыть визард добавления привычки/действия (4 шага). Возвращает [Habit] или null.
Future<Habit?> showAddHabitWizard(
  BuildContext context, {
  DateTime? initialDate,
  HabitDirection? initialDirection,
  HabitMeasurement? initialMeasurement,
  int startStep = 0,
  bool isEventMode = false,
  String? initialCreationSource,
  List<Habit> existingHabits = const [],
}) {
  return showDialog<Habit>(
    context: context,
    builder: (ctx) => AddHabitWizard(
      initialDate: initialDate,
      initialDirection: initialDirection,
      initialMeasurement: initialMeasurement,
      startStep: startStep,
      isEventMode: isEventMode,
      initialCreationSource: initialCreationSource,
      existingHabits: existingHabits,
    ),
  );
}

/// Открыть диалог редактирования привычки. Возвращает [Habit] или null.
Future<Habit?> showEditHabitDialog(
  BuildContext context,
  Habit habit, {
  DateTime? selectedDate,
}) {
  return showDialog<Habit>(
    context: context,
    builder: (ctx) => EditHabitDialog(
      habit: habit,
      selectedDate: selectedDate,
    ),
  );
}
