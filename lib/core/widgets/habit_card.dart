import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../../l10n/app_localizations.dart';

/// Карточка привычки: отображение и отметка в зависимости от [HabitType].
class HabitCard extends StatefulWidget {
  const HabitCard({
    super.key,
    required this.habit,
    this.todayLog,
    required this.logDate,
    this.onTap,
    this.onLog,
    this.dragHandle,
  });

  final Habit habit;
  final HabitLog? todayLog;
  /// Дата, за которую мы отмечаем (обычно выбранный день в календаре).
  final DateTime logDate;
  final VoidCallback? onTap;
  final void Function(HabitLog)? onLog;
  final Widget? dragHandle;

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  bool _timerRunning = false;
  DateTime? _timerStart;
  Timer? _timerTicker;
  double _currentSessionMinutes = 0;

  Habit get habit => widget.habit;
  HabitLog? get todayLog => widget.todayLog;
  void Function(HabitLog)? get onLog => widget.onLog;
  VoidCallback? get onTap => widget.onTap;

  DateTime get _logDay => DateTime(widget.logDate.year, widget.logDate.month, widget.logDate.day);

  bool get _isLogDayToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _logDay.isAtSameMomentAs(today);
  }

  DateTime _logDateTimeNow() {
    final now = DateTime.now();
    return DateTime(_logDay.year, _logDay.month, _logDay.day, now.hour, now.minute, now.second, now.millisecond, now.microsecond);
  }

  double get _goalValue {
    switch (habit.goal.kind) {
      case HabitGoalKind.target:
      case HabitGoalKind.limit:
        return habit.goal.value ?? 1.0;
      case HabitGoalKind.noGoal:
        return 1.0;
    }
  }

  bool? _autoStatusForValue(double newValue) {
    // Если пользователь уже явно отметил success/fail — не переопределяем.
    final existing = todayLog?.isCompleted;
    if (existing == true || existing == false) return existing;

    final goal = _goalValue;
    if (goal <= 0) return null;

    // Для целей (good): как только достигли — success.
    if (habit.goal.kind == HabitGoalKind.target) {
      return newValue >= goal ? true : null;
    }

    // Для лимитов (bad): как только превысили — fail; успех ставим только при закрытии дня.
    if (habit.goal.kind == HabitGoalKind.limit) {
      return newValue > goal ? false : null;
    }

    return null;
  }

  @override
  void dispose() {
    _timerTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    // Для таймеров и счётчиков считаем прогресс для обводки вокруг иконки.
    double? circularProgress;
    if (habit.type == HabitType.timer || habit.type == HabitType.durationLimiter) {
      final baseCurrent = todayLog?.value ?? 0.0;
      final effectiveCurrent = _timerRunning ? baseCurrent + _currentSessionMinutes : baseCurrent;
      final goal = _goalValue;
      if (goal > 0) {
        circularProgress = (effectiveCurrent / goal).clamp(0.0, 1.0);
      }
    } else if (habit.type == HabitType.counter || habit.type == HabitType.limiter) {
      final current = todayLog?.value ?? 0.0;
      final goal = _goalValue;
      if (goal > 0) {
        circularProgress = (current / goal).clamp(0.0, 1.0);
      }
    }

    // Визуальное состояние карточки: активная / успешная / проваленная.
    final bool? completedFlag = todayLog?.isCompleted;

    Color cardColor = theme.colorScheme.surfaceContainerHigh;
    BorderSide borderSide = BorderSide.none;

    if (completedFlag == true) {
      // Успешно выполнено (для любых типов).
      cardColor = cardColor.withValues(alpha: 0.96);
      borderSide = BorderSide(color: Colors.green.shade400.withValues(alpha: 0.7), width: 1.5);
    } else if (completedFlag == false) {
      // Провалено: день закрыт как fail (в т.ч. автозакрытие после окончания дня).
      cardColor = cardColor.withValues(alpha: 0.96);
      borderSide = BorderSide(color: Colors.red.shade400.withValues(alpha: 0.7), width: 1.5);
    }

    // На тёмной теме тёмные цвета (brown и т.п.) сливаются с фоном — осветляем иконку,
    // сохраняя оттенок (HSL даёт более насыщенный результат, чем lerp с белым).
    final iconColor = theme.brightness == Brightness.dark &&
            habit.color.computeLuminance() < 0.25
        ? HSLColor.fromColor(habit.color).withLightness(0.6).toColor()
        : habit.color;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: borderSide,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: habit.type == HabitType.ritual
                    ? Container(
                        decoration: BoxDecoration(
                          color: habit.color.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            habit.icon ?? Icons.star_outline,
                            color: iconColor,
                            size: 32,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: _HabitRingPainter(
                          progress: circularProgress,
                          color: habit.color,
                          trackColor: habit.color.withValues(alpha: 0.18),
                          strokeWidth: 6,
                        ),
                        child: Center(
                          child: Icon(
                            habit.icon ?? Icons.star_outline,
                            color: iconColor,
                            size: 28,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (habit.type == HabitType.ritual) ...[
                                _buildRitualMeta(theme),
                              ] else ...[
                                _buildSubtitle(context, theme, l),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (habit.type == HabitType.counter || habit.type == HabitType.limiter)
                                  IconButton(
                                    onPressed: () {
                                      final current = todayLog?.value ?? 0.0;
                                      final newValue = current + 1;
                                      onLog?.call(
                                        HabitLog(
                                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                                          habitId: habit.id,
                                          date: _logDateTimeNow(),
                                          value: newValue,
                                          isCompleted: _autoStatusForValue(newValue),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    tooltip: 'Быстро добавить',
                                    visualDensity: VisualDensity.compact,
                                  )
                                else if (habit.type == HabitType.timer ||
                                    habit.type == HabitType.durationLimiter)
                                  IconButton(
                                    onPressed: _isLogDayToday
                                        ? () {
                                      final baseCurrent = todayLog?.value ?? 0.0;
                                      _toggleTimer(context, baseCurrent);
                                    }
                                        : null,
                                    icon: Icon(
                                      _timerRunning ? Icons.pause : Icons.play_arrow,
                                    ),
                                    tooltip: _timerRunning ? 'Пауза' : 'Старт',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                IconButton(
                                  onPressed: onTap,
                                  icon: const Icon(Icons.more_horiz),
                                  tooltip: 'Подробнее',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            if (!habit.isActive)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l.recordInactive,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (widget.dragHandle != null)
                          Expanded(
                            child: Center(child: widget.dragHandle),
                          )
                        else
                          const Spacer(),
                        _buildProgressOrAction(context, theme, l),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOrAction(BuildContext context, ThemeData theme, AppLocalizations l) {
    switch (habit.type) {
      case HabitType.ritual:
        final done = todayLog?.isCompleted == true;
        return _BinaryButton(
          done: done,
          isGood: true,
          // Повторное нажатие снимает отметку (переключаем состояние).
          onTap: () => _logBinary(context, !done),
        );
      case HabitType.temptation:
        final isRelapse = todayLog?.isCompleted == false;
        final isHold = todayLog?.isCompleted == true;
        return _TemptationButtons(
          isRelapse: isRelapse,
          isHold: isHold,
          onRelapse: () => _logBinary(context, false),
          onHold: () => _logBinary(context, true),
        );
      case HabitType.counter:
      case HabitType.limiter:
        final done = todayLog?.isCompleted == true;
        return _BinaryButton(
          done: done,
          isGood: habit.isGoodHabit,
          onTap: () => _logBinary(context, !done),
        );
      case HabitType.timer:
      case HabitType.durationLimiter:
        final isSuccess = todayLog?.isCompleted == true;
        final isFail = todayLog?.isCompleted == false;
        return _SuccessFailButtons(
          isSuccess: isSuccess,
          isFail: isFail,
          onSuccess: () => _logBinary(context, true),
          onFail: () => _logBinary(context, false),
        );
    }
  }

  Widget _buildSubtitle(BuildContext context, ThemeData theme, AppLocalizations l) {
    switch (habit.type) {
      case HabitType.counter:
      case HabitType.limiter:
        final current = todayLog?.value ?? 0.0;
        final goal = _goalValue;
        final unit = habit.unit ?? 'раз';
        final text = '${current.toInt()}/${goal.toInt()} $unit';
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _tapCounter(context, current, goal),
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2, right: 4),
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      case HabitType.timer:
      case HabitType.durationLimiter:
        final baseCurrent = todayLog?.value ?? 0.0;
        final effectiveCurrent = _timerRunning ? baseCurrent + _currentSessionMinutes : baseCurrent;
        final goal = _goalValue;

        String format(double minutes) {
          final totalSeconds = (minutes * 60).floor();
          final mm = totalSeconds ~/ 60;
          final ss = totalSeconds % 60;
          return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
        }

        final text = '${format(effectiveCurrent)} / ${format(goal)}';
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _tapTimer(context, baseCurrent, goal),
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2, right: 4),
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      case HabitType.ritual:
        return const SizedBox.shrink();
      case HabitType.temptation:
        final isRelapse = todayLog?.isCompleted == false;
        final isHold = todayLog?.isCompleted == true;
        final text = isRelapse
            ? 'Сегодня был срыв'
            : (isHold ? 'Сегодня держитесь' : 'Сегодня ещё не отмечено');
        return Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
    }
  }

  Widget _buildRitualMeta(ThemeData theme) {
    final schedule = _ritualScheduleText();
    final done = todayLog?.isCompleted == true;
    final statusText = done ? 'Сегодня выполнено' : 'Сегодня не отмечено';

    Color statusBg;
    Color statusFg;
    if (done) {
      statusBg = Colors.green.withValues(alpha: 0.18);
      statusFg = Colors.green.shade400;
    } else {
      statusBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
      statusFg = theme.colorScheme.onSurfaceVariant;
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _RitualChip(
          label: 'Ритуал',
          bg: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
          fg: theme.colorScheme.onSurfaceVariant,
        ),
        _RitualChip(
          label: schedule,
          bg: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          fg: theme.colorScheme.onSurfaceVariant,
        ),
        _RitualChip(
          label: statusText,
          bg: statusBg,
          fg: statusFg,
        ),
      ],
    );
  }

  String _ritualScheduleText() {
    final days = habit.repeatDays.toSet();

    if (days.isEmpty &&
        habit.startDate != null &&
        habit.endDate != null &&
        habit.startDate!.year == habit.endDate!.year &&
        habit.startDate!.month == habit.endDate!.month &&
        habit.startDate!.day == habit.endDate!.day) {
      return 'Одноразовый ритуал';
    }
    if (days.containsAll({1, 2, 3, 4, 5, 6, 7}) && days.length == 7) {
      return 'Каждый день';
    }
    if (days.containsAll({1, 2, 3, 4, 5}) && days.length == 5) {
      return 'По будням';
    }
    if (days.containsAll({6, 7}) && days.length == 2) {
      return 'По выходным';
    }
    if (days.isNotEmpty) {
      return 'По расписанию';
    }
    return 'Без расписания';
  }

  void _logBinary(BuildContext context, bool completed) {
    final currentValue = todayLog?.value;
    final log = HabitLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      habitId: habit.id,
      date: _logDateTimeNow(),
      value: currentValue,
      isCompleted: completed,
    );
    onLog?.call(log);
  }

  void _tapCounter(BuildContext context, double current, double goal) {
    showDialog<double>(
      context: context,
      builder: (ctx) => _NumberInputDialog(
        title: habit.name,
        current: current,
        goal: goal,
        unit: habit.unit ?? 'раз',
        isLimit: habit.type == HabitType.limiter,
      ),
    ).then((value) {
      if (!context.mounted) return;
      if (value != null) {
        final auto = _autoStatusForValue(value);
        onLog?.call(HabitLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          habitId: habit.id,
          date: _logDateTimeNow(),
          value: value,
          isCompleted: auto,
        ));
      }
    });
  }

  void _tapTimer(BuildContext context, double currentMinutes, double goalMinutes) {
    showDialog<double>(
      context: context,
      builder: (ctx) => _NumberInputDialog(
        title: habit.name,
        current: currentMinutes,
        goal: goalMinutes,
        unit: 'мин',
        isLimit: habit.type == HabitType.durationLimiter,
      ),
    ).then((value) {
      if (!context.mounted) return;
      if (value != null) {
        final auto = _autoStatusForValue(value);
        onLog?.call(HabitLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          habitId: habit.id,
          date: _logDateTimeNow(),
          value: value,
          isCompleted: auto,
        ));
      }
    });
  }

  void _toggleTimer(BuildContext context, double currentMinutes) {
    if (!_isLogDayToday) return;
    if (!_timerRunning) {
      // Стартуем новую сессию.
      setState(() {
        _timerRunning = true;
        _timerStart = DateTime.now();
        _currentSessionMinutes = 0;
      });
      _timerTicker?.cancel();
      _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        final start = _timerStart;
        if (!mounted || start == null) return;
        final diff = DateTime.now().difference(start);
        setState(() {
          _currentSessionMinutes = diff.inSeconds / 60.0;
        });
      });
    } else {
      // Останавливаем и записываем дельту в лог.
      final start = _timerStart;
      if (start == null) {
        setState(() {
          _timerRunning = false;
        });
        return;
      }
      _timerTicker?.cancel();
      final diff = DateTime.now().difference(start);
      final minutes = diff.inSeconds / 60.0;
      if (minutes <= 0) {
        setState(() {
          _timerRunning = false;
          _timerStart = null;
          _currentSessionMinutes = 0;
        });
        return;
      }
      final newValue = currentMinutes + minutes;
      final auto = _autoStatusForValue(newValue);
      onLog?.call(HabitLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        habitId: habit.id,
        date: _logDateTimeNow(),
        value: newValue,
        isCompleted: auto,
      ));
      setState(() {
        _timerRunning = false;
        _timerStart = null;
        _currentSessionMinutes = 0;
      });
    }
  }
}

class _RitualChip extends StatelessWidget {
  const _RitualChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _HabitRingPainter extends CustomPainter {
  const _HabitRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double? progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, 0, 2 * math.pi, false, bgPaint);

    if (progress != null && progress! > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweep = 2 * math.pi * progress!.clamp(0.0, 1.0);
      const startAngle = -math.pi / 2; // как в макете — сверху
      canvas.drawArc(rect, startAngle, sweep, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HabitRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _BinaryButton extends StatelessWidget {
  const _BinaryButton({
    required this.done,
    required this.isGood,
    required this.onTap,
  });

  final bool done;
  final bool isGood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = isGood ? Colors.green : Colors.grey;
    final bgColor = done ? baseColor.withValues(alpha: 0.18) : theme.colorScheme.surfaceContainerHighest;
    final borderColor = done ? baseColor : theme.colorScheme.outlineVariant;
    final dotColor = done ? baseColor : theme.colorScheme.outline;
    final text = done ? (isGood ? 'Сделано' : 'Держусь') : (isGood ? 'Отметить' : 'Держись!');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor.withValues(alpha: 0.7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? dotColor : Colors.transparent,
                  border: Border.all(color: dotColor, width: 2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: done ? baseColor : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Две кнопки «Успех» и «Провал» для карточек с таймером/ограничением времени.
class _SuccessFailButtons extends StatelessWidget {
  const _SuccessFailButtons({
    required this.isSuccess,
    required this.isFail,
    required this.onSuccess,
    required this.onFail,
  });

  final bool isSuccess;
  final bool isFail;
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSuccess,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSuccess ? Colors.green.shade400 : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.check_circle_outline,
                    size: 18,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Успех',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: isSuccess ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onFail,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFail ? Colors.red.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isFail ? Colors.red.shade400 : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFail ? Icons.cancel : Icons.cancel_outlined,
                    size: 18,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Провал',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: isFail ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TemptationButtons extends StatelessWidget {
  const _TemptationButtons({
    required this.isRelapse,
    required this.isHold,
    required this.onRelapse,
    required this.onHold,
  });

  final bool isRelapse;
  final bool isHold;
  final VoidCallback onRelapse;
  final VoidCallback onHold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRelapse,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isRelapse ? Colors.red.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Срыв',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: isRelapse ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHold,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isHold ? Colors.green.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHold ? Icons.check_circle : Icons.check_circle_outline,
                      size: 18,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Держусь',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: isHold ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CounterProgress extends StatelessWidget {
  const _CounterProgress({
    required this.current,
    required this.goal,
    required this.unit,
    required this.isLimit,
    required this.color,
    required this.onTap,
    this.onIncrement,
  });

  final double current;
  final double goal;
  final String unit;
  final bool isLimit;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${current.toInt()}/${goal.toInt()} $unit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Ввести значение вручную',
          visualDensity: VisualDensity.compact,
        ),
        if (onIncrement != null)
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Ещё',
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _TimerProgress extends StatelessWidget {
  const _TimerProgress({
    required this.currentMinutes,
    required this.goalMinutes,
    required this.isLimit,
    required this.color,
    required this.onTap,
    required this.isRunning,
    required this.onPlayPause,
  });

  final double currentMinutes;
  final double goalMinutes;
  final bool isLimit;
  final Color color;
  final VoidCallback onTap;
  final bool isRunning;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goalMinutes > 0 ? (currentMinutes / goalMinutes).clamp(0.0, 1.0) : 0.0;
    final displayColor = isLimit ? Colors.orange : color;

    String _format(double minutes) {
      final totalSeconds = (minutes * 60).floor();
      final mm = totalSeconds ~/ 60;
      final ss = totalSeconds % 60;
      return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
    }

    final currentStr = _format(currentMinutes);
    final goalStr = _format(goalMinutes);

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$currentStr / $goalStr',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Ввести время вручную',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: onPlayPause,
          icon: Icon(isRunning ? Icons.pause_circle_outline : Icons.play_circle_outline),
          tooltip: isRunning ? 'Остановить таймер' : 'Запустить таймер',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _NumberInputDialog extends StatefulWidget {
  const _NumberInputDialog({
    required this.title,
    required this.current,
    required this.goal,
    required this.unit,
    required this.isLimit,
  });

  final String title;
  final double current;
  final double goal;
  final String unit;
  final bool isLimit;

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current > 0 ? widget.current.toInt().toString() : '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.isLimit ? 'Сколько было?' : 'Сколько сделали?',
          suffixText: widget.unit,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancelButton),
        ),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(_controller.text.replaceAll(',', '.'));
            if (v != null && v >= 0) Navigator.of(context).pop(v);
          },
          child: Text(l.saveButton),
        ),
      ],
    );
  }
}
