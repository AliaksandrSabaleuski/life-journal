import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/habit.dart';
import '../../../../core/models/habit_log.dart';
import '../../../../core/widgets/habit_card.dart';
import '../../../../l10n/app_localizations.dart';
import 'add_habit_wizard.dart';
import 'edit_habit_dialog.dart';

enum MainListTab { events, habits }

/// Контент главной вкладки: календарная полоса + события/привычки, блок «Новое», мотивационный текст.
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
    required this.currentTab,
    this.onTabChanged,
    this.onAddPressed,
    this.onHabitTap,
    this.onLog,
  });

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
  final MainListTab currentTab;
  final ValueChanged<MainListTab>? onTabChanged;
  final VoidCallback? onAddPressed;
  final void Function(Habit)? onHabitTap;
  final void Function(HabitLog)? onLog;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final active = habits.where((h) => h.isActive && !h.isEvent).toList();
    final inactive = habits.where((h) => !h.isActive && !h.isEvent).toList();

    final bottomPadding = 80.0 + MediaQuery.paddingOf(context).bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalendarStrip(
          isVisible: isMainMenuVisible,
          recenterTrigger: recenterCalendarTrigger,
          initialSelectedDate: selectedDate,
          habits: allHabits,
          onDateSelected: onSelectedDateChanged,
          onTodayVisibilityChanged: onTodayVisibilityInStripChanged,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: SegmentedButton<MainListTab>(
            segments: const [
              ButtonSegment(
                value: MainListTab.events,
                icon: Icon(Icons.event_note_outlined),
                label: Text('События'),
              ),
              ButtonSegment(
                value: MainListTab.habits,
                icon: Icon(Icons.checklist_rtl),
                label: Text('Привычки'),
              ),
            ],
            selected: {currentTab},
            onSelectionChanged: (set) {
              if (onTabChanged != null && set.isNotEmpty) {
                onTabChanged!(set.first);
              }
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: currentTab == MainListTab.habits
                  ? _buildHabitsSection(context, l, active, inactive)
                  : _buildEventsSection(context, l),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHabitsSection(
    BuildContext context,
    AppLocalizations l,
    List<Habit> active,
    List<Habit> inactive,
  ) {
    return [
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: active.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final habit = active[index];
          return HabitCard(
            habit: habit,
            todayLog: todayLogs[habit.id],
            onTap: onHabitTap != null ? () => onHabitTap!(habit) : null,
            onLog: onLog != null ? (log) => onLog!(log) : null,
          );
        },
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
          itemBuilder: (context, index) {
            final habit = inactive[index];
            return HabitCard(
              habit: habit,
              todayLog: todayLogs[habit.id],
              onTap: onHabitTap != null ? () => onHabitTap!(habit) : null,
              onLog: onLog != null ? (log) => onLog!(log) : null,
            );
          },
        ),
      ],
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.all(24),
        child: InkWell(
          onTap: onAddPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              l.newBlockTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          l.motivationalText,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildEventsSection(BuildContext context, AppLocalizations l) {
    final day = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final eventsForDay = habits.where((h) {
      if (!h.isEvent) return false;
      // Для вкладки «События» показываем все записи-события,
      // которые по расписанию попадают в выбранный день.
      return h.isScheduledForDate(day);
    }).toList();

    if (eventsForDay.isEmpty) {
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
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(24),
          child: InkWell(
            onTap: onAddPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                l.newEventTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: eventsForDay.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final habit = eventsForDay[index];
          return HabitCard(
            habit: habit,
            todayLog: todayLogs[habit.id],
            onTap: onHabitTap != null ? () => onHabitTap!(habit) : null,
            onLog: onLog != null ? (log) => onLog!(log) : null,
          );
        },
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.all(24),
        child: InkWell(
          onTap: onAddPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              l.newEventTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }
}

const _dayCellWidth = 52.0;

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

class _CalendarStripState extends State<_CalendarStrip> {
  late final ScrollController _scrollController;
  double? _lastViewportWidth;
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

  List<Color> _indicatorColorsFor(DateTime date, ThemeData theme) {
    final result = <Color>[];
    for (final h in widget.habits) {
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

  void _scheduleRecenterIfSizeChanged(double viewportWidth) {
    if (_lastViewportWidth != null && _lastViewportWidth != viewportWidth) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday(animate: true));
    }
    _lastViewportWidth = viewportWidth;
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
        final viewportWidth = constraints.maxWidth - paddingLeft - paddingRight;
        _scheduleRecenterIfSizeChanged(viewportWidth);
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
                          if (!_isSameDay(_selectedDate, date)) {
                            _selectedDate = date;
                            widget.onDateSelected?.call(date);
                            setState(() {});
                          }
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
                            if (dots.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              SizedBox(
                                height: 8,
                                child: Center(
                                  child: Wrap(
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
                                  ),
                                ),
                              ),
                            ],
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

/// Открыть визард добавления привычки (4 шага). Возвращает [Habit] или null.
Future<Habit?> showAddHabitWizard(
  BuildContext context, {
  DateTime? initialDate,
  HabitDirection? initialDirection,
  HabitMeasurement? initialMeasurement,
  int startStep = 1,
  bool isEventMode = false,
}) {
  return showDialog<Habit>(
    context: context,
    builder: (ctx) => AddHabitWizard(
      initialDate: initialDate,
      initialDirection: initialDirection,
      initialMeasurement: initialMeasurement,
      startStep: startStep,
      isEventMode: isEventMode,
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
