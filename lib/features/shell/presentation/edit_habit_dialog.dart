import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';
import '../../../../l10n/app_localizations.dart';

/// Диалог редактирования привычки: название, иконка, цвет, цель (если есть).
class EditHabitDialog extends StatefulWidget {
  const EditHabitDialog({super.key, required this.habit});

  final Habit habit;

  @override
  State<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends State<EditHabitDialog> {
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  late TextEditingController _unitController;
  late IconData _icon;
  late Color _color;

  static const _presetColors = [
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.deepPurple,
  ];

  static const _presetIcons = [
    Icons.star_rounded,
    Icons.fitness_center,
    Icons.menu_book,
    Icons.water_drop,
    Icons.bed,
    Icons.self_improvement,
    Icons.local_florist,
    Icons.pets,
    Icons.directions_walk,
    Icons.thumb_up_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h.name);
    _icon = h.icon ?? Icons.star_rounded;
    _color = h.color;
    final v = h.goal.value;
    _goalController = TextEditingController(text: v != null ? v.toInt().toString() : '');
    _unitController = TextEditingController(text: h.unit ?? (h.measurement == HabitMeasurement.timed ? 'мин' : 'раз'));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final h = widget.habit;
    final hasGoal = h.measurement != HabitMeasurement.binary;

    return AlertDialog(
      title: const Text('Редактировать привычку'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Text('Иконка', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetIcons.map((icon) {
                  final selected = _icon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = icon),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? theme.colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(icon, color: _color, size: 24),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Цвет', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _presetColors.map((c) {
                  final selected = _color == c;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? theme.colorScheme.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (hasGoal) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _goalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: h.measurement == HabitMeasurement.timed ? 'Минут' : 'Цель (число)',
                    suffixText: _unitController.text.isEmpty ? 'раз' : _unitController.text,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: 'Единица'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancelButton),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            HabitGoal goal;
            if (hasGoal) {
              final v = double.tryParse(_goalController.text.replaceAll(',', '.'));
              goal = h.direction == HabitDirection.good
                  ? HabitGoal.target(v ?? 1.0)
                  : HabitGoal.limit(v ?? 1.0);
            } else {
              goal = h.goal;
            }
            final unit = _unitController.text.trim().isEmpty ? null : _unitController.text.trim();
            Navigator.of(context).pop(Habit(
              id: h.id,
              name: name,
              direction: h.direction,
              measurement: h.measurement,
              goal: goal,
              color: _color,
              icon: _icon,
              unit: unit,
              repeatDays: h.repeatDays,
              isActive: h.isActive,
              reminder: h.reminder,
              startTime: h.startTime,
              endTime: h.endTime,
            ));
          },
          child: Text(l.saveButton),
        ),
      ],
    );
  }
}
