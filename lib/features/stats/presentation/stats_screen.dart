import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';
import '../../../../core/models/habit_log.dart';
import '../../../../core/repositories/habit_logs_repository.dart';
import '../../../../core/repositories/habits_repository.dart';
import 'habit_detail_stats_screen.dart';

enum StatsPeriod { week, month, allTime }

class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.habitsRepository,
    required this.logsRepository,
  });

  final HabitsRepository habitsRepository;
  final HabitLogsRepository logsRepository;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsPeriod _period = StatsPeriod.week;
  bool _loading = true;
  List<Habit> _habits = [];
  List<HabitLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final habits = await widget.habitsRepository.getHabits();
    // В этом прототипе репозиторий хранит только логи за сессию,
    // поэтому просто берём все.
    final logs = <HabitLog>[];
    for (final h in habits) {
      final range = _currentRange();
      final hLogs = await widget.logsRepository.getLogsForHabitInRange(
        h.id,
        range.$1,
        range.$2,
      );
      logs.addAll(hLogs);
    }
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _logs = logs;
      _loading = false;
    });
  }

  (DateTime, DateTime) _currentRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case StatsPeriod.week:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start, start.add(const Duration(days: 6)));
      case StatsPeriod.month:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 0);
        return (start, end);
      case StatsPeriod.allTime:
        // Для in‑memory хранилища просто берём +- большой диапазон.
        final start = today.subtract(const Duration(days: 365 * 5));
        final end = today.add(const Duration(days: 365 * 5));
        return (start, end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final range = _currentRange();
    final habits = _habits.where((h) => !h.isEvent).toList();
    final events = _habits.where((h) => h.isEvent).toList();

    HabitStats computeHabitStats(Habit h) {
      final logs = _logs.where((l) => l.habitId == h.id).toList();
      final totalDays = _countPlannedDays(h, range.$1, range.$2);
      final completedDays = logs.where((l) => l.isCompleted == true).length;
      final percent = totalDays > 0
          ? (completedDays / totalDays * 100).clamp(0, 100).toDouble()
          : null;
      return HabitStats(
        habit: h,
        totalPlannedDays: totalDays,
        completedDays: completedDays,
        percent: percent,
      );
    }

    final habitStats = habits.map(computeHabitStats).toList()
      ..sort((a, b) => (b.percent ?? 0).compareTo(a.percent ?? 0));
    final eventStats = events.map(computeHabitStats).toList()
      ..sort((a, b) => (b.percent ?? 0).compareTo(a.percent ?? 0));

    final allStats = [...habitStats, ...eventStats];
    final overallPercent = allStats.isEmpty
        ? 0.0
        : allStats
                .map((s) => s.percent ?? 0)
                .fold<double>(0, (a, b) => a + b) /
            allStats.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPeriodChips(theme),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _CircleStat(
                            title: 'Всё вместе',
                            percent: overallPercent,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CircleStat(
                            title: 'Привычки',
                            percent: _averagePercent(habitStats),
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CircleStat(
                            title: 'События',
                            percent: _averagePercent(eventStats),
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSummaryCard(
                      context: context,
                      theme: theme,
                      title: 'Привычки',
                      stats: habitStats,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(
                      context: context,
                      theme: theme,
                      title: 'События',
                      stats: eventStats,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Период: ${_formatDate(range.$1)} — ${_formatDate(range.$2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChips(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PeriodChip(
          label: 'Неделя',
          selected: _period == StatsPeriod.week,
          onTap: () {
            setState(() => _period = StatsPeriod.week);
            _load();
          },
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: 'Месяц',
          selected: _period == StatsPeriod.month,
          onTap: () {
            setState(() => _period = StatsPeriod.month);
            _load();
          },
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: 'Всё время',
          selected: _period == StatsPeriod.allTime,
          onTap: () {
            setState(() => _period = StatsPeriod.allTime);
            _load();
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required List<HabitStats> stats,
  }) {
    final active = stats.where((s) => s.habit.isActive).toList();
    final inactive = stats.where((s) => !s.habit.isActive).toList();
    final avgPercent = active.isEmpty
        ? null
        : active
                .map((s) => s.percent ?? 0)
                .fold<double>(0, (a, b) => a + b) /
            active.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              active.isEmpty
                  ? 'Нет активных записей за этот период.'
                  : 'Активных: ${active.length}, неактивных: ${inactive.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (avgPercent != null) ...[
              const SizedBox(height: 8),
              Text(
                'Среднее выполнение: ${avgPercent.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (active.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...active.take(5).map(
                (s) => _HabitStatsTile(
                      stats: s,
                      onTap: () {
                        final range = _currentRange();
                        final logs = _logs
                            .where((l) => l.habitId == s.habit.id)
                            .toList();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => HabitDetailStatsScreen(
                              habit: s.habit,
                              logs: logs,
                              from: range.$1,
                              to: range.$2,
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _averagePercent(List<HabitStats> stats) {
    final active = stats.where((s) => s.habit.isActive).toList();
    if (active.isEmpty) return 0;
    final sum = active
        .map((s) => s.percent ?? 0)
        .fold<double>(0, (a, b) => a + b);
    return sum / active.length;
  }

  int _countPlannedDays(Habit habit, DateTime start, DateTime end) {
    var count = 0;
    var d = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(last)) {
      if (habit.isScheduledForDate(d)) {
        count++;
      }
      d = d.add(const Duration(days: 1));
    }
    return count;
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month.${d.year}';
  }
}

class HabitStats {
  HabitStats({
    required this.habit,
    required this.totalPlannedDays,
    required this.completedDays,
    required this.percent,
  });

  final Habit habit;
  final int totalPlannedDays;
  final int completedDays;
  final double? percent;
}

class _HabitStatsTile extends StatelessWidget {
  const _HabitStatsTile({required this.stats, required this.onTap});

  final HabitStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = stats.percent ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 32,
              decoration: BoxDecoration(
                color: stats.habit.color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.habit.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  LinearProgressIndicator(
                  value: p.isNaN
                      ? 0.0
                      : (p / 100).clamp(0.0, 1.0).toDouble(),
                    minHeight: 4,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(stats.habit.color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${p.toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected ? theme.colorScheme.onPrimary : null,
      ),
    );
  }
}

class _CircleStat extends StatelessWidget {
  const _CircleStat({
    required this.title,
    required this.percent,
    required this.color,
  });

  final String title;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = percent.isNaN ? 0.0 : percent.clamp(0.0, 100.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(
                painter: _DonutPainter(
                  percent: p / 100,
                  color: color,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${p.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.percent,
    required this.color,
    required this.backgroundColor,
  });

  final double percent;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (percent <= 0) return;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percent.clamp(0.0, 1.0);

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
