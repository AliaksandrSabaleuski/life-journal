import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/habit.dart';
import '../../../../core/services/calendar_indicators_service.dart';

/// Высота календарной полосы в хедере `MainShell` (AppBar.bottom).
const double kMainCalendarHeaderHeight = 124;

/// Календарная полоса (дни) для главного экрана.
///
/// Вынесена в отдельный файл, чтобы можно было использовать в `AppBar.bottom`
/// и избежать перекрытия с хедером на разных девайсах.
class MainCalendarStrip extends StatelessWidget {
  const MainCalendarStrip({
    super.key,
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
    const weekdayStrutHeight = 1.25;
    final weekdaySlotHeight =
        textScaler.scale(weekdayFontSize) * weekdayStrutHeight + 8;

    final computedHeight = (verticalPadding +
            weekdaySlotHeight +
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
  static final DateTime _today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToToday(animate: false));
  }

  @override
  void didUpdateWidget(covariant _CalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToToday(animate: true));
    } else if (widget.recenterTrigger != oldWidget.recenterTrigger) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToToday(animate: true));
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
    return todayLeft >= start && todayRight <= end;
  }

  void _scrollToToday({bool animate = false}) {
    if (!mounted) return;
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToToday(animate: animate));
      return;
    }
    final position = _scrollController.position;
    final viewportWidth = position.viewportDimension;
    if (viewportWidth <= 0) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToToday(animate: animate));
      return;
    }
    const itemWidth = _dayCellWidth;
    if (!_isSameDay(_selectedDate, _today)) {
      _selectedDate = _today;
      widget.onDateSelected?.call(_selectedDate);
      setState(() {});
    }
    final todayIndex = _todayIndex;
    final targetOffset =
        (todayIndex * itemWidth) + (itemWidth / 2) - (viewportWidth / 2);
    final clampedOffset = targetOffset.clamp(0.0, position.maxScrollExtent);
    if ((position.pixels - clampedOffset).abs() < 1.0) return;
    if (animate) {
      _scrollController
          .animateTo(
            clampedOffset,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          )
          .then((_) => _notifyTodayVisibility());
    } else {
      _scrollController.jumpTo(clampedOffset);
      _notifyTodayVisibility();
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekdayShortFormat = DateFormat('E', 'ru');
    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context);
    final paddingLeft = padding.left;
    final paddingRight = padding.right;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardBg = const Color(0xFFF3EFE9);

        return Padding(
          padding: EdgeInsets.fromLTRB(paddingLeft, 0, paddingRight, 0),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
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
                final selectedBorder = accent;

                final bgColor = isToday
                    ? headerCoffee.withValues(alpha: 0.10)
                    : Colors.transparent;
                final textColor = headerCoffee;
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
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Builder(
                          builder: (context) {
                            final fs =
                                theme.textTheme.labelSmall?.fontSize ?? 11;
                            final style =
                                theme.textTheme.labelSmall?.copyWith(
                                      fontSize: fs,
                                      color: headerCoffee,
                                      fontWeight: FontWeight.w600,
                                    ) ??
                                    TextStyle(
                                      fontSize: fs,
                                      color: headerCoffee,
                                      fontWeight: FontWeight.w600,
                                    );
                            return Text(
                              weekdayShort,
                              style: style,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              strutStyle: StrutStyle(
                                fontSize: fs,
                                height: 1.25,
                                forceStrutHeight: true,
                              ),
                            );
                          },
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
                                if (index < _totalDays - 1)
                                  Builder(
                                    builder: (context) {
                                      const baseDiameter = 38.0;
                                      const gapToBubble = 2.0;
                                      final scale = isToday ? 1.2 : 1.0;
                                      final bubbleDiameter =
                                          baseDiameter * scale;
                                      final centerX = _dayCellWidth / 2;
                                      final y = 54 / 2;
                                      final left = centerX +
                                          (bubbleDiameter / 2) +
                                          gapToBubble;
                                      final width =
                                          (_dayCellWidth - left).clamp(
                                        0.0,
                                        _dayCellWidth,
                                      );
                                      if (width <= 0.5) {
                                        return const SizedBox.shrink();
                                      }
                                      return Positioned(
                                        top: y,
                                        left: left,
                                        child: SizedBox(
                                          width: width,
                                          height: 1,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: lineColor,
                                              borderRadius:
                                                  BorderRadius.circular(1),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                Transform.scale(
                                  scale: isToday ? 1.2 : 1.0,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final baseFill = bgColor ==
                                                  Colors.transparent
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
                                                stops: const [
                                                  0.0,
                                                  0.55,
                                                  1.0,
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.85,
                                                ),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white.withValues(
                                                    alpha: 0.65,
                                                  ),
                                                  blurRadius: 8,
                                                  offset: const Offset(-2, -3),
                                                ),
                                                BoxShadow(
                                                  color: Colors.black.withValues(
                                                    alpha: 0.08,
                                                  ),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '${date.day}',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: isToday
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
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
                                                color:
                                                    selectedBorder.withValues(
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

