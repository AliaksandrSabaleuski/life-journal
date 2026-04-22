import 'package:flutter/material.dart';

import '../../../../app/strings_ru.dart';

/// Первое окно при добавлении записи: выбор типа привычки — хорошая или плохая.
/// Возвращает [true] для хорошей, [false] для плохой, [null] при отмене.
class ChooseHabitTypeDialog extends StatelessWidget {
  const ChooseHabitTypeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text(StringsRu.chooseHabitTypeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            StringsRu.chooseHabitTypeHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TypeCard(
                  icon: Icons.thumb_up_rounded,
                  label: StringsRu.goodHabitLabel,
                  color: Colors.green,
                  onTap: () => Navigator.of(context).pop<bool>(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TypeCard(
                  icon: Icons.thumb_down_rounded,
                  label: StringsRu.badHabitLabel,
                  color: Colors.orange,
                  onTap: () => Navigator.of(context).pop<bool>(false),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<bool?>(null),
          child: const Text(StringsRu.cancel),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
