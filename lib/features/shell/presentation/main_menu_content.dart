import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/habit.dart';
import '../../../../core/models/habit_log.dart';
import '../../../../core/services/calendar_indicators_service.dart';
import '../../../../core/widgets/active_habit_card.dart';
import '../../../../core/widgets/bool_habit_card.dart';
import '../../../../core/widgets/habit_counter_card.dart';
import '../../../../core/ui/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import 'add_habit_wizard.dart';
import '../shell_content_insets.dart';

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

    bool isBoolType(Habit h) {
      final hd = h.forDate(selectedDate);
      return hd.type == HabitType.ritual || hd.type == HabitType.temptation;
    }

    void sortForToday(List<Habit> list) {
      // Делает порядок детерминированным (dart sort не stable).
      final originalIndexById = <String, int>{
        for (final e in list.asMap().entries) e.value.id: e.key,
      };

      // Сортировка:
      // 1) невыполненные сверху, выполненные снизу (isCompleted == true)
      // 2) внутри группы: булевые сверху, каунтер/таймер ниже
      // 3) иначе сохраняем исходный порядок
      list.sort((a, b) {
        final aDone = todayLogs[a.id]?.isCompleted == true;
        final bDone = todayLogs[b.id]?.isCompleted == true;
        if (aDone != bDone) return aDone ? 1 : -1;

        final aBool = isBoolType(a);
        final bBool = isBoolType(b);
        if (aBool != bBool) return aBool ? -1 : 1;

        return (originalIndexById[a.id] ?? 0) - (originalIndexById[b.id] ?? 0);
      });
    }

    sortForToday(active);
    sortForToday(inactive);

    final bottomPadding = ShellContentInsets.bottom(context) + 12;
    final result = Padding(
      padding: EdgeInsets.only(top: ShellContentInsets.top(context)),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 6, 28, 10),
          child: _CalendarStripWithRecenter(
          isVisible: isMainMenuVisible,
          recenterTrigger: recenterCalendarTrigger,
          initialSelectedDate: selectedDate,
          habits: allHabits,
          onDateSelected: onSelectedDateChanged,
          onTodayVisibilityChanged: onTodayVisibilityInStripChanged,
          ),
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
    ),
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
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _EmptyHabitsCard(
            title: 'Нет привычек',
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
        const SizedBox(height: 8),
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
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, index) {
            final habit = inactive[index];
            final h = habit.forDate(selectedDate);
            final todayLog = todayLogs[habit.id];
            final onTap =
                onHabitTap != null ? () => onHabitTap!(habit) : null;

            if (h.type == HabitType.counter) {
              final goal = h.goal.value?.round() ?? 1;
              final current = (todayLog?.value ?? 0).round();
              return HabitCounterCard(
                title: h.name,
                unit: h.unit ?? 'раз',
                current: current,
                goal: goal,
                isCompleted: todayLog?.isCompleted == true,
                isSkipped: todayLog?.isCompleted == false,
                accent: Theme.of(ctx).colorScheme.primary,
                customColor: h.color.value == 0 ? null : h.color,
                onOpenEdit: onTap,
                onSetValue: onLog == null
                    ? null
                    : (value) {
                        final reachedGoal = goal > 0 && value >= goal;
                        onLog!(
                          HabitLog(
                            id: todayLog?.id ??
                                '${habit.id}_${selectedDate.millisecondsSinceEpoch}',
                            habitId: habit.id,
                            date: DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              12,
                              0,
                            ),
                            value: value.toDouble(),
                            isCompleted:
                                reachedGoal ? true : todayLog?.isCompleted,
                          ),
                        );
                      },
                onAdd: onLog == null
                    ? null
                    : () {
                        final newValue = current + 1;
                        final reachedGoal = goal > 0 && newValue >= goal;
                        onLog!(
                          HabitLog(
                            id: todayLog?.id ??
                                '${habit.id}_${selectedDate.millisecondsSinceEpoch}',
                            habitId: habit.id,
                            date: DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              12,
                              0,
                            ),
                            value: newValue.toDouble(),
                            isCompleted:
                                reachedGoal ? true : todayLog?.isCompleted,
                          ),
                        );
                      },
              );
            }

            if (h.type == HabitType.timer) {
              final goalMinutes = h.goal.value?.round() ?? 15;
              final initialSeconds = ((todayLog?.value ?? 0.0) * 60).round();
              return ActiveHabitCard(
                  title: h.name,
                  unit: h.unit ?? 'мин',
                  goalMinutes: goalMinutes,
                  accent: Theme.of(ctx).colorScheme.primary,
                  initialSeconds: initialSeconds,
                  isCompleted: todayLog?.isCompleted == true,
                  customColor: h.color.value == 0 ? null : h.color,
                  onOpenEdit: onTap,
                  onSave: onLog == null
                      ? null
                      : (duration) {
                          final minutes = duration.inSeconds / 60.0;
                          final reachedGoal =
                              goalMinutes > 0 && minutes >= goalMinutes;
                          onLog!(
                            HabitLog(
                              id: todayLog?.id ??
                                  '${habit.id}_${selectedDate.millisecondsSinceEpoch}',
                              habitId: habit.id,
                              date: DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                12,
                                0,
                              ),
                              value: minutes,
                              isCompleted: reachedGoal
                                  ? true
                                  : todayLog?.isCompleted,
                            ),
                          );
                        },
              );
            }

            if (h.type == HabitType.ritual ||
                h.type == HabitType.temptation) {
              final BoolHabitState state = todayLog?.isCompleted == true
                  ? BoolHabitState.done
                  : (todayLog?.isCompleted == false
                      ? BoolHabitState.skipped
                      : BoolHabitState.notDone);
              return GestureDetector(
                onTap: onTap,
                child: BoolHabitCard(
                  title: h.name,
                  state: state,
                  customColor: h.color.value == 0 ? null : h.color,
                  onToggle: onLog == null
                      ? null
                      : () {
                          final bool? next =
                              state == BoolHabitState.done ? null : true;
                          onLog!(
                            HabitLog(
                              id: todayLog?.id ??
                                  '${habit.id}_${selectedDate.millisecondsSinceEpoch}',
                              habitId: habit.id,
                              date: DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                12,
                                0,
                              ),
                              isCompleted: next,
                            ),
                          );
                        },
                ),
              );
            }

            // Других типов нет.
            return const SizedBox.shrink();
          },
        ),
      ],
    ];
  }

}

class _EmptyHabitsCard extends StatelessWidget {
  const _EmptyHabitsCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const coffee = Color(0xFF6B5A4E);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: Center(
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    size: 86,
                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: coffee.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    // Адаптивная высота под разные устройства и textScale.
    // Стрип содержит: label (день недели) + gap + кружок дня + gap + точки + вертикальные паддинги контейнера.
    const double verticalPadding = 8 * 2;
    // Максимальный размер "плашки дня" — с кольцом выделения.
    const double circleSize = 44;
    const double dotsHeight = 8;
    const double gap1 = 4;
    const double gap2 = 3;

    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final weekdayFontSize = theme.textTheme.labelSmall?.fontSize ?? 11;
    final weekdayLineHeight = theme.textTheme.labelSmall?.height ?? 1.2;
    final weekdayTextHeight = textScaler.scale(weekdayFontSize) * weekdayLineHeight;

    // Немного запаса на разные шрифты/рендеринг.
    final computedHeight = (verticalPadding +
            weekdayTextHeight +
            gap1 +
            circleSize +
            gap2 +
            dotsHeight +
            6)
        .clamp(104.0, 140.0);

    return SizedBox(
      height: computedHeight,
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

  HabitLog _buildLog({
    required Habit habit,
    required DateTime day,
    required double value,
    bool? isCompleted,
  }) {
    return HabitLog(
      id: widget.todayLogs[habit.id]?.id ??
          '${habit.id}_${day.millisecondsSinceEpoch}',
      habitId: habit.id,
      date: DateTime(day.year, day.month, day.day, 12, 0),
      value: value,
      isCompleted: isCompleted,
    );
  }

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
        final h = habit.forDate(widget.logDate);
        final todayLog = widget.todayLogs[habit.id];
        final VoidCallback? onTap =
            widget.onHabitTap != null ? () => widget.onHabitTap!(habit) : null;

        Widget card;
        if (h.type == HabitType.counter) {
          final goal = h.goal.value?.round() ?? 1;
          final current = (todayLog?.value ?? 0).round();
          card = HabitCounterCard(
            title: h.name,
            unit: h.unit ?? 'раз',
            current: current,
            goal: goal,
            isCompleted: todayLog?.isCompleted == true,
            isSkipped: todayLog?.isCompleted == false,
            accent: Theme.of(context).colorScheme.primary,
            customColor: h.color.value == 0 ? null : h.color,
            onOpenEdit: onTap,
            onSetValue: widget.onLog == null
                ? null
                : (value) {
                    final reachedGoal = goal > 0 && value >= goal;
                    final log = _buildLog(
                      habit: habit,
                      day: widget.logDate,
                      value: value.toDouble(),
                      // Ручной ввод может "развыполнить" привычку.
                      // Если значение ниже цели — сбрасываем completed в null.
                      isCompleted: reachedGoal ? true : null,
                    );
                    widget.onLog!(log);
                  },
            onAdd: widget.onLog == null
                ? null
                : () {
                    final newValue = current + 1;
                    final reachedGoal = goal > 0 && newValue >= goal;
                    final log = _buildLog(
                      habit: habit,
                      day: widget.logDate,
                      value: newValue.toDouble(),
                      isCompleted: reachedGoal ? true : todayLog?.isCompleted,
                    );
                    widget.onLog!(log);
                  },
          );
        } else if (h.type == HabitType.timer) {
          final goalMinutes = h.goal.value?.round() ?? 15;
          final initialSeconds = ((todayLog?.value ?? 0.0) * 60).round();
          card = ActiveHabitCard(
            title: h.name,
            unit: h.unit ?? 'мин',
            goalMinutes: goalMinutes,
            accent: Theme.of(context).colorScheme.primary,
            initialSeconds: initialSeconds,
            isCompleted: todayLog?.isCompleted == true,
            customColor: h.color.value == 0 ? null : h.color,
            onOpenEdit: onTap,
            onSave: widget.onLog == null
                ? null
                : (duration) {
                    final minutes = duration.inSeconds / 60.0;
                    final reachedGoal =
                        goalMinutes > 0 && minutes >= goalMinutes;
                    final log = _buildLog(
                      habit: habit,
                      day: widget.logDate,
                      value: minutes,
                      // Ручное сохранение таймера тоже может "развыполнить".
                      isCompleted: reachedGoal ? true : null,
                    );
                    widget.onLog!(log);
                  },
          );
        } else {
          // Boolean habits & events: ritual / temptation
          final done = todayLog?.isCompleted == true;
          card = GestureDetector(
            onTap: onTap,
            child: BoolHabitCard(
              title: h.name,
              state: todayLog?.isCompleted == true
                  ? BoolHabitState.done
                  : (todayLog?.isCompleted == false
                      ? BoolHabitState.skipped
                      : BoolHabitState.notDone),
              customColor: h.color.value == 0 ? null : h.color,
              onToggle: widget.onLog == null
                  ? null
                  : () {
                      final bool? next = done ? null : true;
                      widget.onLog!(
                        HabitLog(
                          id: todayLog?.id ??
                              '${habit.id}_${widget.logDate.millisecondsSinceEpoch}',
                          habitId: habit.id,
                          date: DateTime(
                            widget.logDate.year,
                            widget.logDate.month,
                            widget.logDate.day,
                            12,
                            0,
                          ),
                          isCompleted: next,
                        ),
                      );
                    },
            ),
          );
        }

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
            // Вертикальный отступ держим за счёт margin карточек.
            if (index < _items.length - 1) const SizedBox(height: 0),
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
      final hd = h.forDate(date);
      if (!hd.isScheduledForDate(date)) continue;
      result.add(effectiveHabitIndicatorColor(hd.color));
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
    // Боковые отступы (16) задаются снаружи в MainMenuContent.
    // Здесь оставляем только safe-area, чтобы края совпадали с карточками.
    final paddingLeft = padding.left;
    final paddingRight = padding.right;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Базовая подложка дня — тёплый серо-бежевый как в референсе.
        final cardBg = const Color(0xFFF3EFE9);

        return Padding(
          // Внешние отступы задаются снаружи (в MainMenuContent).
          // Здесь держим только safe-area по бокам, иначе ломаем динамическую высоту и ловим overflow.
          padding: EdgeInsets.fromLTRB(paddingLeft, 0, paddingRight, 0),
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
                      final rawWeekdayShort = weekdayShortFormat.format(date);
                      final weekdayShort = rawWeekdayShort.isEmpty
                          ? rawWeekdayShort
                          : rawWeekdayShort[0].toUpperCase() +
                              rawWeekdayShort.substring(1).toLowerCase();
                      const coffee = Color(0xFF6B5A4E);
                      final accent = theme.colorScheme.primary;
                      final headerCoffee = coffee.withValues(alpha: 0.92);
                      final lineColor = coffee.withValues(alpha: 0.20);
                      final baseBorder = coffee.withValues(alpha: 0.30);
                      final selectedBorder = accent;

                      final bgColor = isToday
                          ? headerCoffee.withValues(alpha: 0.10)
                          : Colors.transparent;
                      final textColor = headerCoffee;
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
                                    color: headerCoffee,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: _dayCellWidth,
                                  height: 54,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      // Соединитель между соседними баблами (между кругами).
                                      if (index < _totalDays - 1)
                                        Builder(
                                          builder: (context) {
                                            const baseDiameter = 38.0;
                                            const gapToBubble = 2.0;
                                            // Увеличиваем именно "сегодня", а не выбранный день.
                                            final scale = isToday ? 1.2 : 1.0;
                                            final bubbleDiameter = baseDiameter * scale;
                                            final centerX = _dayCellWidth / 2;
                                            final y = 54 / 2;
                                            final left = centerX + (bubbleDiameter / 2) + gapToBubble;
                                            final width = (_dayCellWidth - left).clamp(0.0, _dayCellWidth);
                                            if (width <= 0.5) return const SizedBox.shrink();
                                            return Positioned(
                                              top: y,
                                              left: left,
                                              child: SizedBox(
                                                width: width,
                                                height: 1,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: lineColor,
                                                    borderRadius: BorderRadius.circular(1),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                      // Сам "бабл" дня. Выбранный день увеличиваем на 20%.
                                      Transform.scale(
                                        scale: isToday ? 1.2 : 1.0,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Builder(
                                              builder: (context) {
                                                // Для "сегодня" делаем тёплый кофейный тинт, а не серый альфа-слой.
                                                final baseFill = bgColor == Colors.transparent
                                                    ? cardBg
                                                    : bgColor;
                                                final fill = isToday
                                                    ? Color.lerp(
                                                        cardBg,
                                                        headerCoffee,
                                                        0.22,
                                                      )!
                                                    : baseFill;
                                                final topHighlight = Color.lerp(
                                                  Colors.white,
                                                  fill,
                                                  0.10,
                                                )!;
                                                final bottomShade = Color.lerp(
                                                  const Color(0xFFB9ADA2),
                                                  fill,
                                                  0.65,
                                                )!;

                                                return Container(
                                                  width: 38,
                                                  height: 38,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        topHighlight,
                                                        fill,
                                                        bottomShade,
                                                      ],
                                                      stops: const [0.0, 0.55, 1.0],
                                                    ),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      // Белая обводка как в референсе.
                                                      color: Colors.white.withValues(alpha: 0.85),
                                                      width: 1,
                                                    ),
                                                    boxShadow: [
                                                      // Верхний блик
                                                      BoxShadow(
                                                        color: Colors.white.withValues(alpha: 0.65),
                                                        blurRadius: 8,
                                                        offset: const Offset(-2, -3),
                                                      ),
                                                      // Нижняя тень
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.08),
                                                        blurRadius: 12,
                                                        offset: const Offset(0, 8),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    '${date.day}',
                                                    style: theme.textTheme.titleSmall?.copyWith(
                                                      // Размер/жирность цифры не меняем при выборе дня.
                                                      // Акцент можно оставлять только для "сегодня".
                                                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            if (isSelected)
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: selectedBorder.withValues(
                                                        alpha: 0.22,
                                                      ),
                                                      blurRadius: 5,
                                                      spreadRadius: 0.0,
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: selectedBorder,
                                                    width: 2.6,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            SizedBox(
                              height: 6,
                              child: Center(
                                child: dots.isNotEmpty
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: dots
                                            .take(6)
                                            .map(
                                              (c) => Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 1,
                                                ),
                                                child: Container(
                                                  width: 3,
                                                  height: 3,
                                                  decoration: BoxDecoration(
                                                    color: c.withValues(alpha: 0.75),
                                                    borderRadius:
                                                        BorderRadius.circular(1.5),
                                                  ),
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

