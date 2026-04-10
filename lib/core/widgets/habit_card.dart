import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import 'time_input_dialog.dart';

/// Карточка привычки: отображение и отметка в зависимости от [HabitType].
class HabitCard extends StatefulWidget {
  const HabitCard({
    super.key,
    required this.habit,
    this.todayLog,
    required this.logDate,
    this.onTap,
    this.onLog,
  });

  final Habit habit;
  final HabitLog? todayLog;
  /// Дата, за которую мы отмечаем (обычно выбранный день в календаре).
  final DateTime logDate;
  final VoidCallback? onTap;
  final void Function(HabitLog)? onLog;

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  Habit get habit => widget.habit;
  HabitLog? get todayLog => widget.todayLog;
  void Function(HabitLog)? get onLog => widget.onLog;
  VoidCallback? get onTap => widget.onTap;

  Timer? _timer;
  int _elapsedSeconds = 0;

  bool get _timerRunning => _timer != null && _timer!.isActive;

  double get _goalValue {
    switch (habit.goal.kind) {
      case HabitGoalKind.target:
        return habit.goal.value ?? 1.0;
      case HabitGoalKind.noGoal:
        return 1.0;
    }
  }

  double get _timerCurrentMinutes {
    if (_timerRunning) {
      return _elapsedSeconds / 60.0;
    }
    return todayLog?.value ?? 0.0;
  }

  void _startTimer() {
    final goalMinutes = _goalValue;
    if (goalMinutes <= 0) return;
    final baseSeconds = ((todayLog?.value ?? 0.0) * 60).floor();
    _elapsedSeconds = baseSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        final goalSeconds = (goalMinutes * 60).floor();
        if (_elapsedSeconds >= goalSeconds) {
          _timer?.cancel();
          _timer = null;
          onLog?.call(HabitLog(
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
            value: goalMinutes,
            isCompleted: true,
          ));
        }
      });
    });
    setState(() {});
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    final savedMinutes = _elapsedSeconds / 60.0;
    final goalMinutes = _goalValue;
    onLog?.call(HabitLog(
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
      value: savedMinutes,
      isCompleted: goalMinutes > 0 && savedMinutes >= goalMinutes
          ? true
          : todayLog?.isCompleted,
    ));
    setState(() {});
  }

  Future<void> _setManualTimerMinutes(BuildContext context) async {
    final initialMinutes = (_timerRunning
            ? (_elapsedSeconds / 60.0)
            : (todayLog?.value ?? 0.0))
        .round()
        .clamp(0, 9999);
    final result = await showTimeInputDialog(context, initial: initialMinutes);
    if (!mounted) return;
    if (result == null) return;

    // Останавливаем таймер, если он был запущен, и сохраняем введённое значение.
    _timer?.cancel();
    _timer = null;
    _elapsedSeconds = result * 60;

    final goalMinutes = _goalValue;
    final savedMinutes = result.toDouble();
    onLog?.call(HabitLog(
      id: todayLog?.id ?? '${habit.id}_${widget.logDate.millisecondsSinceEpoch}',
      habitId: habit.id,
      date: DateTime(
        widget.logDate.year,
        widget.logDate.month,
        widget.logDate.day,
        12,
        0,
      ),
      value: savedMinutes,
      isCompleted: goalMinutes > 0 && savedMinutes >= goalMinutes
          ? true
          : todayLog?.isCompleted,
    ));
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Для таймеров и счётчиков считаем прогресс для обводки вокруг иконки.
    double? circularProgress;
    if (habit.type == HabitType.timer) {
      final effectiveCurrent = _timerCurrentMinutes;
      final goal = _goalValue;
      if (goal > 0) {
        circularProgress = (effectiveCurrent / goal).clamp(0.0, 1.0);
      }
    } else if (habit.type == HabitType.counter) {
      final current = todayLog?.value ?? 0.0;
      final goal = _goalValue;
      if (goal > 0) {
        circularProgress = (current / goal).clamp(0.0, 1.0);
      }
    }

    // Визуальное состояние карточки: активная / успешная / проваленная.
    final bool? completedFlag = todayLog?.isCompleted;

    final baseCardColor = Colors.white.withValues(alpha: 0.72);
    Color cardColor = baseCardColor;
    BorderSide borderSide = BorderSide.none;
    final shadowColor = Colors.black.withValues(alpha: 0.06);

    if (completedFlag == true) {
      // Успешно выполнено: чуть спокойнее, но в той же гамме.
      cardColor = baseCardColor.withValues(alpha: 0.64);
      borderSide = BorderSide(
        color: theme.colorScheme.primary.withValues(alpha: 0.18),
        width: 1.2,
      );
    } else if (completedFlag == false) {
      // Провалено: день закрыт как fail (в т.ч. автозакрытие после окончания дня).
      cardColor = baseCardColor.withValues(alpha: 0.68);
      borderSide = BorderSide(
        color: theme.colorScheme.error.withValues(alpha: 0.22),
        width: 1.2,
      );
    }

    // На тёмной теме тёмные цвета (brown и т.п.) сливаются с фоном — осветляем иконку,
    // сохраняя оттенок (HSL даёт более насыщенный результат, чем lerp с белым).
    final iconColor = theme.brightness == Brightness.dark &&
            habit.color.computeLuminance() < 0.25
        ? HSLColor.fromColor(habit.color).withLightness(0.6).toColor()
        : habit.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.fromBorderSide(borderSide),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 55,
                height: 55,
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
                            size: 26,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: _HabitRingPainter(
                          progress: circularProgress,
                          color: habit.color.withValues(alpha: 0.95),
                          trackColor: habit.color.withValues(alpha: 0.12),
                          strokeWidth: 4.5,
                        ),
                        child: Center(
                          child: Icon(
                            habit.icon ?? Icons.star_outline,
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.86),
                            ),
                          ),
                          const SizedBox(height: 1),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: habit.type == HabitType.timer ||
                                habit.type == HabitType.counter
                            ? (habit.type == HabitType.timer
                                ? GestureDetector(
                                    onTap: onLog == null
                                        ? null
                                        : () => _setManualTimerMinutes(context),
                                    behavior: HitTestBehavior.opaque,
                                    child: _buildProgressSubtitle(theme),
                                  )
                                : _buildProgressSubtitle(theme))
                            : Text(
                                (todayLog?.isCompleted == true)
                                    ? 'Выполнено'
                                    : 'Не выполнено',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: (todayLog?.isCompleted == true)
                                      ? theme.colorScheme.primary
                                          .withValues(alpha: 0.85)
                                      : theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if ((habit.type == HabitType.counter || habit.type == HabitType.timer) &&
                  onLog != null)
                SizedBox(
                  height: 55,
                  child: Center(
                    child: todayLog?.isCompleted == true
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              size: 28,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.9),
                            ),
                          )
                        : habit.type == HabitType.timer
                            ? IconButton(
                                onPressed: _timerRunning ? _pauseTimer : _startTimer,
                                iconSize: 28,
                                icon: Icon(
                                  _timerRunning ? Icons.pause : Icons.play_arrow,
                                  color: theme.colorScheme.primary,
                                ),
                                tooltip: _timerRunning
                                    ? 'Пауза'
                                    : 'Запустить таймер',
                              )
                            : IconButton(
                                onPressed: () {
                                  final current = todayLog?.value ?? 0.0;
                                  final newValue = current + 1;
                                  final goal = _goalValue;
                                  final reachedGoal = goal > 0 && newValue >= goal;
                                  final log = HabitLog(
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
                                    value: newValue,
                                    isCompleted:
                                        reachedGoal ? true : todayLog?.isCompleted,
                                  );
                                  onLog!(log);
                                },
                                iconSize: 28,
                                icon: Icon(Icons.add, color: theme.colorScheme.primary),
                                tooltip: 'Добавить',
                              ),
                  ),
                )
              else if (habit.type != HabitType.timer &&
                  habit.type != HabitType.counter &&
                  onLog != null)
                SizedBox(
                  height: 55,
                  child: Center(
                    child: IconButton(
                      onPressed: () {
                        // true = выполнено, null = сброшено (без подстветки). false = провалено (красная обводка).
                        final bool? completed =
                            todayLog?.isCompleted == true ? null : true;
                        final log = HabitLog(
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
                          isCompleted: completed,
                        );
                        onLog!(log);
                      },
                      iconSize: 28,
                      icon: Icon(
                        todayLog?.isCompleted == true
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: todayLog?.isCompleted == true
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: todayLog?.isCompleted == true
                            ? theme.colorScheme.primary.withValues(alpha: 0.14)
                            : null,
                      ),
                      tooltip: todayLog?.isCompleted == true
                          ? 'Отменить'
                          : 'Отметить выполненным',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Показываем только каунтер или время, если задана цель.
  Widget _buildProgressSubtitle(ThemeData theme) {
    switch (habit.type) {
      case HabitType.counter:
        if (habit.goal.kind != HabitGoalKind.target) return const SizedBox.shrink();
        final current = todayLog?.value ?? 0.0;
        final goal = _goalValue;
        final unit = habit.unit ?? 'раз';
        return Text(
          '${current.toInt()}/${goal.toInt()} $unit',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        );
      case HabitType.timer:
        if (habit.goal.kind != HabitGoalKind.target) return const SizedBox.shrink();
        final current = _timerCurrentMinutes;
        final goal = _goalValue;

        String formatMinutes(double minutes) {
          final totalSeconds = (minutes * 60).floor();
          final mm = totalSeconds ~/ 60;
          final ss = totalSeconds % 60;
          return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
        }

        return Text(
          '${formatMinutes(current)} / ${formatMinutes(goal)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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

