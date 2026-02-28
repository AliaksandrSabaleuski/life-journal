import 'package:flutter/material.dart';
import '../models/habit.dart';

/// Карточка привычки: круглый прогресс с иконкой, название, метрики (цель, попытка, рекорд).
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    this.onTap,
  });

  final Habit habit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = habit.currentGoalDays > 0
        ? (habit.attemptCount / habit.currentGoalDays).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: habit.color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(habit.color),
                    ),
                    Icon(habit.icon, color: habit.color, size: 28),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _MetricChip(
                          label: 'Текущая цель',
                          value: '${habit.currentGoalDays} дн.',
                        ),
                        const SizedBox(width: 8),
                        _MetricChip(
                          label: 'Попытка',
                          value: '${habit.attemptCount}',
                        ),
                        const SizedBox(width: 8),
                        _MetricChip(
                          label: 'Рекорд',
                          value: '${habit.recordDays} дн.',
                        ),
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
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '$label: $value',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
