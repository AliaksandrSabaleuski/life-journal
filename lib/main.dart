import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const JournalApp());
}

class JournalApp extends StatelessWidget {
  const JournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Дневник событий',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('ru');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('ru');
      },
      home: const TodayEventsPage(),
    );
  }
}

class TodayEventsPage extends StatefulWidget {
  const TodayEventsPage({super.key});

  @override
  State<TodayEventsPage> createState() => _TodayEventsPageState();
}

class _TodayEventsPageState extends State<TodayEventsPage> {
  final List<String> _events = [];
  DateTime _selectedDate = DateTime.now();
  bool _isTodayVisible = true;

  static String _eventsKeyForDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'events_${year}_${month}_$day';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _eventsKeyForDate(_selectedDate);
    final stored = prefs.getStringList(key);
    if (stored != null) {
      setState(() {
        _events
          ..clear()
          ..addAll(stored);
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _eventsKeyForDate(_selectedDate);
    await prefs.setStringList(key, _events);
  }

  Future<void> _addEvent() async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.newEventTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            decoration: InputDecoration(
              hintText: l.newEventHint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(context).pop(text);
                }
              },
              child: Text(l.saveButton),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _events.insert(0, result);
      });
      await _saveEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final formattedDate =
        '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}';
    final monthYearTitle =
        '${_monthName(_selectedDate.month)} ${_selectedDate.year}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () {
            // Пока без выбора даты, просто оставим заготовку.
          },
        ),
        title: Text(
          monthYearTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (!_isTodayVisible)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: l.backToTodayTooltip,
              onPressed: () {
                setState(() {
                  _selectedDate = today;
                });
                _loadEvents();
              },
            ),
          IconButton(
            icon: const Icon(Icons.star_outline),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(l.subscriptionTitle),
                    content: Text(l.subscriptionBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l.closeButton),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MonthDaysHorizontal(
            centerDate: today,
            selectedDate: _selectedDate,
            today: today,
            onSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
              _loadEvents();
            },
            onTodayVisibilityChanged: (visible) {
              if (_isTodayVisible != visible) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() {
                    _isTodayVisible = visible;
                  });
                });
              }
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _events.isEmpty
                ? Center(
                    child: Text(
                      l.noEventsForDay,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Text(
                          _isSameDay(_selectedDate, today)
                              ? '${l.todayLabel}, $formattedDate'
                              : '${_weekdayShortName(_selectedDate.weekday)}, $formattedDate',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _events.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            final number = _events.length - index;

                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(number.toString()),
                              ),
                              title: Text(event),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addButton),
      ),
    );
  }
}

String _monthName(int month) {
  const names = [
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
  return names[month - 1];
}

String _weekdayShortName(int weekday) {
  const names = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];
  return names[(weekday - 1) % 7];
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MonthDaysHorizontal extends StatefulWidget {
  const _MonthDaysHorizontal({
    required this.centerDate,
    required this.selectedDate,
    required this.today,
    required this.onSelected,
    required this.onTodayVisibilityChanged,
  });

  final DateTime centerDate;
  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;
  final ValueChanged<bool> onTodayVisibilityChanged;

  static const int daysBefore = 3650; // ~10 лет назад
  static const int daysAfter = 3650; // ~10 лет вперёд

  @override
  State<_MonthDaysHorizontal> createState() => _MonthDaysHorizontalState();
}

class _MonthDaysHorizontalState extends State<_MonthDaysHorizontal> {
  late final ScrollController _controller;
  bool _lastTodayVisible = true;

  DateTime get _startDate {
    final c =
        DateTime(widget.centerDate.year, widget.centerDate.month, widget.centerDate.day);
    return c.subtract(const Duration(days: _MonthDaysHorizontal.daysBefore));
  }

  int get _itemCount =>
      _MonthDaysHorizontal.daysBefore + _MonthDaysHorizontal.daysAfter + 1;

  int _indexForDate(DateTime date) {
    final start = _startDate;
    return date.difference(start).inDays.clamp(0, _itemCount - 1);
  }

  double _offsetForIndex(int index, double width) {
    const itemWidth = 52.0;
    const spacing = 8.0;
    const horizontalPadding = 12.0;

    final center =
        horizontalPadding + index * (itemWidth + spacing) + itemWidth / 2;
    return center - width / 2;
  }

  @override
  void initState() {
    super.initState();
    final width = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final index = _indexForDate(widget.selectedDate);
    final initialOffset = _offsetForIndex(index, width.width);
    _controller = ScrollController(initialScrollOffset: initialOffset);
    _controller.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTodayVisibility());
  }

  @override
  void didUpdateWidget(covariant _MonthDaysHorizontal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        final width = context.size?.width ??
            (MediaQuery.maybeOf(context)?.size.width ?? 360);
        final index = _indexForDate(widget.selectedDate);
        final offset = _offsetForIndex(index, width);
        _controller.animateTo(
          offset.clamp(0.0, _controller.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
    _updateTodayVisibility();
  }

  void _handleScroll() => _updateTodayVisibility();

  void _updateTodayVisibility() {
    if (!_controller.hasClients) return;
    final viewport = _controller.position.viewportDimension;
    final offset = _controller.offset;

    final todayIndex = _indexForDate(widget.today);

    const itemWidth = 52.0;
    const spacing = 8.0;
    const horizontalPadding = 12.0;

    final left = horizontalPadding + todayIndex * (itemWidth + spacing);
    final right = left + itemWidth;

    final visible = right > offset && left < offset + viewport;

    if (visible != _lastTodayVisible) {
      _lastTodayVisible = visible;
      widget.onTodayVisibilityChanged(visible);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startDate = _startDate;

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: _controller,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _itemCount,
        itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
          final isSelected = _isSameDay(date, widget.selectedDate);
          final isToday = _isSameDay(date, widget.today);

          Color bgColor;
          Color textColor;

          if (isSelected) {
            bgColor = theme.colorScheme.primary;
            textColor = theme.colorScheme.onPrimary;
          } else if (isToday) {
            bgColor = theme.colorScheme.primaryContainer;
            textColor = theme.colorScheme.onPrimaryContainer;
          } else {
            bgColor = theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3);
            textColor = theme.colorScheme.onSurfaceVariant;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onSelected(date),
              child: Container(
                width: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weekdayShortName(date.weekday),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.day.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
