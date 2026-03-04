import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';
import '../../../../l10n/app_localizations.dart';

/// Включить замеры производительности календаря.
/// Логи с префиксом [PERF] — скопируй и скинь для анализа.
const bool _kDebugCalendarPerf = true;

/// Экран календаря: переключатель Месяц/Год; вид месяца — скролл по месяцам с цифрами дней.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.selectedTabIndex,
    required this.calendarTabIndex,
    required this.habits,
  });

  /// Текущая вкладка в shell (0=главная, 1=календарь, 2=статистика, 3=ассистент).
  final int selectedTabIndex;
  /// Индекс вкладки календаря в shell (обычно 1).
  final int calendarTabIndex;
  /// Все привычки — нужны для индикаторов в сетке.
  final List<Habit> habits;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isMonthView = true;
  ScrollController? _scrollController;
  ScrollController? _yearScrollController;
  final ValueNotifier<DateTime?> _selectedDateNotifier = ValueNotifier<DateTime?>(null);
  bool _monthFirstFrameLogged = false;
  bool _yearFirstFrameLogged = false;

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasOnCalendar = oldWidget.selectedTabIndex == oldWidget.calendarTabIndex;
    final isOnCalendar = widget.selectedTabIndex == widget.calendarTabIndex;
    if (wasOnCalendar && !isOnCalendar) {
      _selectedDateNotifier.value = null;
    }
    if (!wasOnCalendar && isOnCalendar) {
      setState(() => _isMonthView = true);
    }
  }

  static const List<String> _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const List<String> _monthNames = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  /// Январь 2022 — декабрь 2036.
  static const int _startYear = 2022;
  static const int _endYear = 2036;
  static int get _monthCount =>
      (_endYear - _startYear + 1) * 12; // 180 месяцев

  static (int year, int month) _monthAt(int index) {
    final totalMonths = index;
    final y = _startYear + (totalMonths ~/ 12);
    final m = (totalMonths % 12) + 1;
    return (y, m);
  }

  static int _indexFor(int year, int month) {
    return (year - _startYear) * 12 + (month - 1);
  }

  /// Высота одного блока месяца (фиксированная для расчёта скролла).
  static const double _monthBlockHeight = 300;

  @override
  void initState() {
    super.initState();
    if (_kDebugCalendarPerf) {
      debugPrint('[PERF] CALENDAR_TAB_OPENED');
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _yearScrollController?.dispose();
    _selectedDateNotifier.dispose();
    super.dispose();
  }

  double _initialScrollOffset(double viewportHeight) {
    final now = DateTime.now();
    if (now.year < _startYear || now.year > _endYear) return 0;
    if (now.year == _startYear && now.month < 1) return 0;
    if (now.year == _endYear && now.month > 12) return 0;
    final currentIndex = _indexFor(now.year, now.month);
    final maxOffset = (_monthCount * _monthBlockHeight) - viewportHeight;
    if (maxOffset <= 0) return 0;
    final offset = (currentIndex * _monthBlockHeight) -
        (viewportHeight / 2) +
        (_monthBlockHeight / 2);
    return offset.clamp(0.0, maxOffset);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(l.calendarViewMonth)),
              ButtonSegment(value: false, label: Text(l.calendarViewYear)),
            ],
            selected: {_isMonthView},
            onSelectionChanged: (Set<bool> selected) {
              final isMonthView = selected.first;
              if (_kDebugCalendarPerf) {
                debugPrint('[PERF] SWITCH_TO_${isMonthView ? "MONTH" : "YEAR"}');
              }
              setState(() => _isMonthView = isMonthView);
              _selectedDateNotifier.value = null;
            },
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _isMonthView ? 0 : 1,
            children: [
              _buildMonthViewContent(theme),
              _buildYearViewContent(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthViewContent(ThemeData theme) {
    if (_kDebugCalendarPerf) {
      debugPrint('[PERF] MONTH_VIEW_BUILD_START');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekdays
                .map((w) => Expanded(
                      child: Center(
                        child: Text(w, style: theme.textTheme.labelSmall),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _scrollController ??= ScrollController(
                initialScrollOffset: _initialScrollOffset(constraints.maxHeight),
              );
              if (_kDebugCalendarPerf && !_monthFirstFrameLogged) {
                _monthFirstFrameLogged = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  debugPrint('[PERF] MONTH_VIEW_FIRST_FRAME_DONE');
                });
              }
              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemExtent: _monthBlockHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _monthCount,
                  itemBuilder: (context, index) {
                    final (year, month) = _monthAt(index);
                    return _MonthBlock(
                      year: year,
                      month: month,
                      monthName: _monthNames[month - 1],
                      today: DateTime.now(),
                      habits: widget.habits,
                      selectedDateNotifier: _selectedDateNotifier,
                      onDaySelected: (date) {
                        if (_kDebugCalendarPerf) {
                          final t0 = DateTime.now();
                          _selectedDateNotifier.value = date;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            debugPrint('[PERF] MONTH_DAY_SELECT date=$date frame_done_ms=${DateTime.now().difference(t0).inMilliseconds}');
                          });
                        } else {
                          _selectedDateNotifier.value = date;
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static const int _yearStart = 2022;
  static const int _yearEnd = 2036;
  static int get _yearCount => _yearEnd - _yearStart + 1;

  /// Высота одного блока года (фиксированная для центрирования, как у месяцев).
  /// Чуть увеличена с запасом, чтобы исключить визуальный оверфлоу при
  /// разных сочетаниях строк с точками и без них.
  static const double _yearBlockHeight = 780;

  double _initialYearScrollOffset(double viewportHeight) {
    final now = DateTime.now();
    if (now.year < _yearStart || now.year > _yearEnd) return 0;
    final currentIndex = now.year - _yearStart;
    final maxOffset = (_yearCount * _yearBlockHeight) - viewportHeight;
    if (maxOffset <= 0) return 0;
    final offset = (currentIndex * _yearBlockHeight) -
        (viewportHeight / 2) +
        (_yearBlockHeight / 2);
    return offset.clamp(0.0, maxOffset);
  }

  Widget _buildYearViewContent(ThemeData theme) {
    final today = DateTime.now();
    if (_kDebugCalendarPerf) {
      debugPrint('[PERF] YEAR_VIEW_BUILD_START');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _yearScrollController ??= ScrollController(
          initialScrollOffset: _initialYearScrollOffset(constraints.maxHeight),
        );
        if (_kDebugCalendarPerf && !_yearFirstFrameLogged) {
          _yearFirstFrameLogged = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint('[PERF] YEAR_VIEW_FIRST_FRAME_DONE');
          });
        }
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
          ),
          child: ListView.builder(
            controller: _yearScrollController,
            itemExtent: _yearBlockHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _yearCount,
            itemBuilder: (context, index) {
              final y = _yearStart + index;
              return _YearBlock(
                year: y,
                monthNames: _monthNames,
                today: today,
                habits: widget.habits,
                selectedDateNotifier: _selectedDateNotifier,
                onDaySelected: (date) {
                  if (_kDebugCalendarPerf) {
                    final t0 = DateTime.now();
                    developer.Timeline.startSync('CalendarDaySelected');
                    _selectedDateNotifier.value = date;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      developer.Timeline.finishSync();
                      debugPrint('[PERF] YEAR_DAY_SELECT date=$date frame_done_ms=${DateTime.now().difference(t0).inMilliseconds}');
                    });
                  } else {
                    _selectedDateNotifier.value = date;
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Один год: заголовок и 12 месяцев. Слушатель выбора — в каждом мини-месяце, чтобы пересобирались только 2 месяца, а не весь год.
class _YearBlock extends StatelessWidget {
  const _YearBlock({
    required this.year,
    required this.monthNames,
    required this.today,
    required this.habits,
    required this.selectedDateNotifier,
    required this.onDaySelected,
  });

  final int year;
  final List<String> monthNames;
  final DateTime today;
   /// Все привычки — для индикаторов в мини-месяцах.
  final List<Habit> habits;
  final ValueListenable<DateTime?> selectedDateNotifier;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '$year',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int row = 0; row < 4; row++) ...[
                  if (row > 0) const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int col = 0; col < 3; col++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: col > 0 ? 5.0 : 0,
                              right: col < 2 ? 5.0 : 0,
                            ),
                            child: _MiniMonthGrid(
                              year: year,
                              month: row * 3 + col + 1,
                              monthName: monthNames[row * 3 + col],
                              today: today,
                              habits: habits,
                              selectedDateNotifier: selectedDateNotifier,
                              onDaySelected: onDaySelected,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Один месяц в скролле. Сетка не знает о выборе; подсветка — оверлей поверх (один слушатель, без пересборки ячеек).
class _MonthBlock extends StatelessWidget {
  const _MonthBlock({
    required this.year,
    required this.month,
    required this.monthName,
    required this.today,
    required this.habits,
    required this.selectedDateNotifier,
    required this.onDaySelected,
  });

  final int year;
  final int month;
  final String monthName;
  final DateTime today;
  final List<Habit> habits;
  final ValueListenable<DateTime?> selectedDateNotifier;
  final ValueChanged<DateTime> onDaySelected;

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static const double _cellHeight = 40;
  static const double _cellSize = 36;
  static const double _titleHeight = 24;
  static const double _titleGap = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    final daysInMonth = last.day;
    final leadingEmpty = first.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$monthName $year',
                style:
                    theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: _titleGap),
              Table(
                border: TableBorder.symmetric(inside: BorderSide.none),
                children: List.generate(rows, (rowIndex) {
                  return TableRow(
                    children: List.generate(7, (colIndex) {
                      final cellIndex = rowIndex * 7 + colIndex;
                      if (cellIndex < leadingEmpty) {
                        return const SizedBox(height: _cellHeight, child: Center());
                      }
                      final day = cellIndex - leadingEmpty + 1;
                      if (day > daysInMonth) {
                        return const SizedBox(height: _cellHeight, child: Center());
                      }
                      final date = DateTime(year, month, day);
                      final isToday = _isSameDay(date, today);
                      final dots = _indicatorColorsFor(date);
                      return _DayCell(
                        day: day,
                        isToday: isToday,
                        indicatorColors: dots,
                        onTap: () => onDaySelected(date),
                      );
                    }),
                  );
                }),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ValueListenableBuilder<DateTime?>(
                    valueListenable: selectedDateNotifier,
                    builder: (context, selectedDate, _) {
                      if (selectedDate == null ||
                          selectedDate.year != year ||
                          selectedDate.month != month) {
                        return const SizedBox.shrink();
                      }
                      final first = DateTime(year, month, 1);
                      final leadingEmpty = first.weekday - 1;
                      final index = leadingEmpty + selectedDate.day - 1;
                      final row = index ~/ 7;
                      final col = index % 7;
                      final cellW = constraints.maxWidth / 7;
                      final left = col * cellW + (cellW - _cellSize) / 2;
                      final top = _titleHeight +
                          _titleGap +
                          row * _cellHeight +
                          (_cellHeight - _cellSize) / 2;
                      return Stack(
                        children: [
                          Positioned(
                            left: left,
                            top: top,
                            width: _cellSize,
                            height: _cellSize,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(_cellSize / 2),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.9),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _indicatorColorsFor(DateTime date) {
    final result = <Color>[];
    for (final h in habits) {
      if (!h.isScheduledForDate(date)) continue;
      result.add(h.color);
      if (result.length == 6) break;
    }
    return result;
  }
}

/// Ячейка дня (вид «Месяц»). Выбор не знает — подсветка рисуется оверлеем.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.indicatorColors,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final List<Color> indicatorColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool highlighted = isToday;
    final Color? bgColor =
        highlighted ? theme.colorScheme.primaryContainer : null;
    final Color textColor = highlighted
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: highlighted
                        ? Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.9,
                            ),
                            width: 3,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                ),
                if (indicatorColors.isNotEmpty)
                  Positioned(
                    bottom: 3,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: indicatorColors
                          .take(6)
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Один мини-месяц в виде года. Сетка не знает о выборе; подсветка — оверлей поверх.
class _MiniMonthGrid extends StatelessWidget {
  const _MiniMonthGrid({
    required this.year,
    required this.month,
    required this.monthName,
    required this.today,
    required this.habits,
    required this.selectedDateNotifier,
    required this.onDaySelected,
  });

  final int year;
  final int month;
  final String monthName;
  final DateTime today;
  final List<Habit> habits;
  final ValueListenable<DateTime?> selectedDateNotifier;
  final ValueChanged<DateTime> onDaySelected;

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static const double _miniCellHeight = 18;
  static const double _miniCellSize = 16;
  static const double _miniTitleHeight = 16;
  static const double _miniTitleGap = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    final daysInMonth = last.day;
    final leadingEmpty = first.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                monthName,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: _miniTitleGap),
            Table(
              border: TableBorder.symmetric(inside: BorderSide.none),
              children: List.generate(rows, (rowIndex) {
                // Сначала смотрим, есть ли хотя бы один день с индикатором в этом ряду.
                bool rowHasDots = false;
                for (int colIndex = 0; colIndex < 7; colIndex++) {
                  final cellIndex = rowIndex * 7 + colIndex;
                  if (cellIndex < leadingEmpty) continue;
                  final day = cellIndex - leadingEmpty + 1;
                  if (day > daysInMonth) continue;
                  final date = DateTime(year, month, day);
                  if (_indicatorColorsFor(date).isNotEmpty) {
                    rowHasDots = true;
                    break;
                  }
                }

                return TableRow(
                  children: List.generate(7, (colIndex) {
                    final cellIndex = rowIndex * 7 + colIndex;
                    if (cellIndex < leadingEmpty) {
                      return SizedBox(height: rowHasDots ? _miniCellHeight : (_miniCellHeight - 4), child: const Center());
                    }
                    final day = cellIndex - leadingEmpty + 1;
                    if (day > daysInMonth) {
                      return SizedBox(height: rowHasDots ? _miniCellHeight : (_miniCellHeight - 4), child: const Center());
                    }
                    final date = DateTime(year, month, day);
                    final isToday = _isSameDay(date, today);
                    final dots = _indicatorColorsFor(date);
                    return _MiniDayCell(
                      day: day,
                      isToday: isToday,
                      indicatorColors: dots,
                      hasRowDots: rowHasDots,
                      onTap: () => onDaySelected(date),
                    );
                  }),
                );
              }),
            ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ValueListenableBuilder<DateTime?>(
                  valueListenable: selectedDateNotifier,
                  builder: (context, selectedDate, _) {
                    if (selectedDate == null ||
                        selectedDate.year != year ||
                        selectedDate.month != month) {
                      return const SizedBox.shrink();
                    }
                    final first = DateTime(year, month, 1);
                    final leadingEmpty = first.weekday - 1;
                    final index = leadingEmpty + selectedDate.day - 1;
                    final row = index ~/ 7;
                    final col = index % 7;
                    final cellW = constraints.maxWidth / 7;
                    final left = col * cellW + (cellW - _miniCellSize) / 2;
                    final top = _miniTitleHeight +
                        _miniTitleGap +
                        row * _miniCellHeight +
                        (_miniCellHeight - _miniCellSize) / 2;
                    return Stack(
                      children: [
                        Positioned(
                          left: left,
                          top: top,
                          width: _miniCellSize,
                          height: _miniCellSize,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(_miniCellSize / 2),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.9),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  List<Color> _indicatorColorsFor(DateTime date) {
    final result = <Color>[];
    for (final h in habits) {
      if (!h.isScheduledForDate(date)) continue;
      result.add(h.color);
      if (result.length == 3) break;
    }
    return result;
  }
}

/// Ячейка дня в виде года. Выбор не знает — подсветка рисуется оверлеем.
class _MiniDayCell extends StatelessWidget {
  const _MiniDayCell({
    required this.day,
    required this.isToday,
    required this.indicatorColors,
    required this.hasRowDots,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final List<Color> indicatorColors;
  final bool hasRowDots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final outerHeight = hasRowDots ? 18.0 : 14.0;

    return SizedBox(
      height: outerHeight,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 16,
            height: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isToday ? theme.colorScheme.primaryContainer : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.9,
                            ),
                            width: 2,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, -2),
                    child: Text(
                      '$day',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: isToday
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                if (indicatorColors.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: indicatorColors
                          .take(3)
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
