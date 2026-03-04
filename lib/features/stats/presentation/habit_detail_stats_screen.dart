import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';
import '../../../../core/models/habit_log.dart';

class HabitDetailStatsScreen extends StatelessWidget {
  const HabitDetailStatsScreen({
    super.key,
    required this.habit,
    required this.logs,
    required this.from,
    required this.to,
  });

  final Habit habit;
  final List<HabitLog> logs;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final days = _buildDaySeries();
    final completedDays =
        days.where((d) => d.status == _DayStatus.success).length;
    final failedDays =
        days.where((d) => d.status == _DayStatus.fail).length;
    final plannedDays = days.length;
    final donePercent =
        plannedDays > 0 ? (completedDays / plannedDays * 100) : 0.0;

    final weekdaySuccess = List<int>.filled(7, 0);
    final weekdayFail = List<int>.filled(7, 0);
    for (final d in days) {
      final w = d.date.weekday - 1;
      if (d.status == _DayStatus.success) weekdaySuccess[w]++;
      if (d.status == _DayStatus.fail) weekdayFail[w]++;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(theme, donePercent, completedDays, plannedDays),
              const SizedBox(height: 16),
              _buildWeekdayChart(theme, weekdaySuccess, weekdayFail),
              const SizedBox(height: 16),
              _buildTimeline(theme, days),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    ThemeData theme,
    double donePercent,
    int completedDays,
    int plannedDays,
  ) {
    final p = donePercent.clamp(0.0, 100.0);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _DonutPainter(
                  percent: p / 100,
                  color: habit.color,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                ),
                child: Center(
                  child: Text(
                    '${p.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'За период',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedDays из $plannedDays дней с отметкой',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _InfoChip(
                        label: habit.type.toString().split('.').last,
                      ),
                      if (habit.unit != null)
                        _InfoChip(label: 'Ед.: ${habit.unit}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayChart(
    ThemeData theme,
    List<int> success,
    List<int> fail,
  ) {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final maxVal = [
      ...success,
      ...fail,
    ].fold<int>(0, (a, b) => math.max(a, b));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'По дням недели',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final s = success[i].toDouble();
                  final f = fail[i].toDouble();
                  final total = s + f;
                  final h = maxVal == 0 ? 0.0 : total / maxVal;
                  final hClamped = h.isNaN ? 0.0 : h.clamp(0.0, 1.0);
                  final hSuccess =
                      total == 0 ? 0.0 : (s / total).clamp(0.0, 1.0);

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              width: 14,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  height: 120 * (hClamped == 0.0 ? 0.0 : hClamped),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: FractionallySizedBox(
                                        heightFactor: hSuccess,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: habit.color,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              bottom: Radius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[i],
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme, List<_DayEntry> days) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Лента по дням',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Последние ${math.min(14, days.length)} дней',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...days.take(14).map(
              (d) {
                IconData icon;
                Color color;
                String text;
                switch (d.status) {
                  case _DayStatus.success:
                    icon = Icons.check_circle;
                    color = Colors.greenAccent;
                    text = 'Выполнено';
                    break;
                  case _DayStatus.fail:
                    icon = Icons.cancel;
                    color = Colors.redAccent;
                    text = 'Срыв / не выполнено';
                    break;
                  case _DayStatus.missed:
                    icon = Icons.radio_button_unchecked;
                    color = theme.colorScheme.onSurfaceVariant;
                    text = 'Без отметки';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: 8),
                      Text(
                        _formatDay(d.date),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<_DayEntry> _buildDaySeries() {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    final map = <DateTime, HabitLog>{};
    for (final log in logs) {
      map[log.dateOnly] = log;
    }

    final List<_DayEntry> result = [];
    var d = start;
    while (!d.isAfter(end)) {
      final log = map[d];
      _DayStatus status;
      if (log == null) {
        status = _DayStatus.missed;
      } else if (log.isCompleted == true) {
        status = _DayStatus.success;
      } else if (log.isCompleted == false) {
        status = _DayStatus.fail;
      } else {
        status = _DayStatus.missed;
      }
      result.add(_DayEntry(date: d, status: status));
      d = d.add(const Duration(days: 1));
    }
    result.sort((a, b) => b.date.compareTo(a.date)); // от новых к старым
    return result;
  }

  String _formatDay(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}

enum _DayStatus { success, fail, missed }

class _DayEntry {
  _DayEntry({required this.date, required this.status});

  final DateTime date;
  final _DayStatus status;
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

