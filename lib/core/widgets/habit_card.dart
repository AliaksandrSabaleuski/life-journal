import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../../l10n/app_localizations.dart';

/// Карточка привычки: отображение и отметка в зависимости от [HabitType].
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    this.todayLog,
    this.onTap,
    this.onLog,
  });

  final Habit habit;
  final HabitLog? todayLog;
  final VoidCallback? onTap;
  final void Function(HabitLog)? onLog;

  double get _goalValue {
    switch (habit.goal.kind) {
      case HabitGoalKind.target:
      case HabitGoalKind.limit:
        return habit.goal.value ?? 1.0;
      case HabitGoalKind.noGoal:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: habit.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  habit.icon ?? Icons.star_outline,
                  color: habit.color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!habit.isActive)
                          Container(
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
                    const SizedBox(height: 6),
                    _buildProgressOrAction(context, theme, l),
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
        return _BinaryButton(
          done: todayLog?.isCompleted == true,
          isGood: true,
          onTap: () => _logBinary(context, true),
        );
      case HabitType.temptation:
        return _BinaryButton(
          done: todayLog != null,
          isGood: todayLog?.isCompleted != false,
          isRelapse: todayLog?.isCompleted == false,
          onTap: () => _tapTemptation(context),
        );
      case HabitType.counter:
      case HabitType.limiter:
        final current = todayLog?.value ?? 0.0;
        final goal = _goalValue;
        final isLimit = habit.type == HabitType.limiter;
        return _CounterProgress(
          current: current,
          goal: goal,
          unit: habit.unit ?? 'раз',
          isLimit: isLimit,
          color: habit.color,
          onTap: () => _tapCounter(context, current, goal),
        );
      case HabitType.timer:
      case HabitType.durationLimiter:
        final current = todayLog?.value ?? 0.0;
        final goal = _goalValue;
        final isLimit = habit.type == HabitType.durationLimiter;
        return _TimerProgress(
          currentMinutes: current,
          goalMinutes: goal,
          isLimit: isLimit,
          color: habit.color,
          onTap: () => _tapTimer(context, current, goal),
        );
    }
  }

  void _logBinary(BuildContext context, bool completed) {
    final log = HabitLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      habitId: habit.id,
      date: DateTime.now(),
      isCompleted: completed,
    );
    onLog?.call(log);
  }

  void _tapTemptation(BuildContext context) {
    if (todayLog != null) return; // уже отметили на сегодня
    showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Как сегодня?'),
        content: const Text(
          'Отметьте срыв или то, что вы удержались.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Сорвался'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удержался'),
          ),
        ],
      ),
    ).then((result) {
      if (!context.mounted) return;
      if (result != null) _logBinary(context, result);
    });
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
        onLog?.call(HabitLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          habitId: habit.id,
          date: DateTime.now(),
          value: value,
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
        onLog?.call(HabitLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          habitId: habit.id,
          date: DateTime.now(),
          value: value,
        ));
      }
    });
  }
}

class _BinaryButton extends StatelessWidget {
  const _BinaryButton({
    required this.done,
    required this.isGood,
    this.isRelapse = false,
    required this.onTap,
  });

  final bool done;
  final bool isGood;
  final bool isRelapse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isRelapse
                ? Colors.red.withValues(alpha: 0.15)
                : (done
                    ? (isGood ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2))
                    : Colors.grey.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRelapse ? Icons.warning_amber_rounded : (done ? Icons.check_circle : Icons.radio_button_unchecked),
                size: 22,
                color: isRelapse ? Colors.red : (done ? (isGood ? Colors.green : Colors.grey) : Colors.grey),
              ),
              const SizedBox(width: 6),
              Text(
                isRelapse ? 'Срыв' : (done ? (isGood ? 'Сделано' : 'Держусь') : (isGood ? 'Отметить' : 'Держись!')),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isRelapse ? Colors.red : (done ? null : Colors.grey),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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
  });

  final double current;
  final double goal;
  final String unit;
  final bool isLimit;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final displayColor = isLimit ? Colors.orange : color;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: displayColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(displayColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${current.toInt()}/${goal.toInt()} $unit',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
  });

  final double currentMinutes;
  final double goalMinutes;
  final bool isLimit;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goalMinutes > 0 ? (currentMinutes / goalMinutes).clamp(0.0, 1.0) : 0.0;
    final displayColor = isLimit ? Colors.orange : color;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: displayColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(displayColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${currentMinutes.toInt()}/${goalMinutes.toInt()} мин',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
