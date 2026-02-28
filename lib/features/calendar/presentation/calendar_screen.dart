import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Экран календаря: переключатель Месяц/Год; вид месяца — скролл по месяцам с цифрами дней.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isMonthView = true;
  ScrollController? _scrollController;
  ScrollController? _yearScrollController;
  DateTime? _selectedDate;

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
  void dispose() {
    _scrollController?.dispose();
    _yearScrollController?.dispose();
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
              setState(() => _isMonthView = selected.first);
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
                      selectedDate: _selectedDate,
                      onDaySelected: (date) =>
                          setState(() => _selectedDate = date),
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
  static const double _yearBlockHeight = 620;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        _yearScrollController ??= ScrollController(
          initialScrollOffset: _initialYearScrollOffset(constraints.maxHeight),
        );
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
                selectedDate: _selectedDate,
                onDaySelected: (date) =>
                    setState(() => _selectedDate = date),
              );
            },
          ),
        );
      },
    );
  }
}

/// Один год в виде «ГОД YYYY»: заголовок и 12 месяцев без дней недели, с подсветкой сегодня/выбранного.
class _YearBlock extends StatelessWidget {
  const _YearBlock({
    required this.year,
    required this.monthNames,
    required this.today,
    required this.selectedDate,
    required this.onDaySelected,
  });

  final int year;
  final List<String> monthNames;
  final DateTime today;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
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
                            selectedDate: selectedDate,
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
    );
  }
}

/// Один месяц в скролле: заголовок «Март 2026» и сетка дней с подсветкой сегодня/выбранного.
class _MonthBlock extends StatelessWidget {
  const _MonthBlock({
    required this.year,
    required this.month,
    required this.monthName,
    required this.today,
    required this.selectedDate,
    required this.onDaySelected,
  });

  final int year;
  final int month;
  final String monthName;
  final DateTime today;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDaySelected;

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    final firstWeekday = first.weekday;
    final daysInMonth = last.day;
    final leadingEmpty = firstWeekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$monthName $year',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.symmetric(
              inside: BorderSide.none,
            ),
            children: List.generate(rows, (rowIndex) {
              return TableRow(
                children: List.generate(7, (colIndex) {
                  final cellIndex = rowIndex * 7 + colIndex;
                  if (cellIndex < leadingEmpty) {
                    return const SizedBox(height: 40, child: Center());
                  }
                  final day = cellIndex - leadingEmpty + 1;
                  if (day > daysInMonth) {
                    return const SizedBox(height: 40, child: Center());
                  }
                  final date = DateTime(year, month, day);
                  final isToday = _isSameDay(date, today);
                  final isSelected =
                      selectedDate != null && _isSameDay(date, selectedDate!);

                  return _DayCell(
                    day: day,
                    isToday: isToday,
                    isSelected: isSelected,
                    onTap: () => onDaySelected(date),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : isToday
                        ? theme.colorScheme.primaryContainer
                        : null,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '$day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : isToday
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMonthGrid extends StatelessWidget {
  const _MiniMonthGrid({
    required this.year,
    required this.month,
    required this.monthName,
    required this.today,
    required this.selectedDate,
    required this.onDaySelected,
  });

  final int year;
  final int month;
  final String monthName;
  final DateTime today;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDaySelected;

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    final firstWeekday = first.weekday;
    final daysInMonth = last.day;
    final leadingEmpty = firstWeekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            monthName,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.symmetric(
            inside: BorderSide.none,
          ),
          children: List.generate(rows, (rowIndex) {
            return TableRow(
              children: List.generate(7, (colIndex) {
                final cellIndex = rowIndex * 7 + colIndex;
                if (cellIndex < leadingEmpty) {
                  return const SizedBox(height: 18, child: Center());
                }
                final day = cellIndex - leadingEmpty + 1;
                if (day > daysInMonth) {
                  return const SizedBox(height: 18, child: Center());
                }
                final date = DateTime(year, month, day);
                final isToday = _isSameDay(date, today);
                final isSelected =
                    selectedDate != null && _isSameDay(date, selectedDate!);

                return _MiniDayCell(
                  day: day,
                  isToday: isToday,
                  isSelected: isSelected,
                  onTap: () => onDaySelected(date),
                );
              }),
            );
          }),
        ),
      ],
    );
  }
}

class _MiniDayCell extends StatelessWidget {
  const _MiniDayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 18,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : isToday
                        ? theme.colorScheme.primaryContainer
                        : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$day',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : isToday
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
