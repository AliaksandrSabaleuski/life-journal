import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';
import '../../../../l10n/app_localizations.dart';

/// Диалог редактирования привычки: название, иконка, цвет, цель (если есть).
class EditHabitDialog extends StatefulWidget {
  const EditHabitDialog({
    super.key,
    required this.habit,
    this.selectedDate,
  });

  final Habit habit;
  final DateTime? selectedDate;

  @override
  State<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends State<EditHabitDialog> {
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  late TextEditingController _unitController;
  late IconData _icon;
  late Color _color;

  late bool _limitNotExceed;
  late bool _isOneTime;
  late Set<int> _repeatWeekdays;
  DateTime? _endDate;
  TimeOfDay? _reminder;

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

    _limitNotExceed = h.measurement == HabitMeasurement.counted
        ? h.goal.kind == HabitGoalKind.limit
        : h.direction == HabitDirection.bad;

    _reminder = h.reminder;

    final start = h.startDate;
    final end = h.endDate;
    final sameDay = start != null &&
        end != null &&
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    _isOneTime = h.repeatDays.isEmpty && sameDay;
    if (_isOneTime) {
      _repeatWeekdays = <int>{};
      _endDate = end;
    } else {
      _repeatWeekdays = h.repeatDays.isNotEmpty
          ? Set<int>.from(h.repeatDays)
          : <int>{1, 2, 3, 4, 5, 6, 7};
      _endDate = end;
    }
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
    final isBinary = h.measurement == HabitMeasurement.binary;

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
              const SizedBox(height: 16),
              _buildGoalSection(theme, h, isBinary),
              const SizedBox(height: 16),
              _buildReminderSection(theme, l),
              const SizedBox(height: 16),
              _buildScheduleSection(theme),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final h = widget.habit;
            final base = widget.selectedDate != null
                ? DateTime(widget.selectedDate!.year, widget.selectedDate!.month, widget.selectedDate!.day)
                : DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

            final newEnd = base.subtract(const Duration(days: 1));

            DateTime? startDate = h.startDate;
            if (startDate != null && newEnd.isBefore(startDate)) {
              // Если "удаляем" до начала действия — считаем привычку неактивной.
              Navigator.of(context).pop(
                h.copyWith(isActive: false),
              );
              return;
            }

            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Удалить привычку?'),
                content: const Text(
                  'Привычка будет скрыта из списка активных и перейдёт в раздел неактивных.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l.cancelButton),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            );
            if (confirm == true && mounted) {
              Navigator.of(context).pop(
                h.copyWith(endDate: newEnd),
              );
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Удалить'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancelButton),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            HabitGoal goal;
            String? unit;

            if (isBinary) {
              final v = double.tryParse(_goalController.text.replaceAll(',', '.'));
              if (v != null && v > 0) {
                goal = HabitGoal.target(v);
                unit = 'раз';
              } else {
                goal = const HabitGoal.noGoal();
              }
            } else if (h.measurement == HabitMeasurement.counted) {
              final v = double.tryParse(_goalController.text.replaceAll(',', '.')) ?? 1.0;
              unit = _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'раз';
              final isLimitGoal = _limitNotExceed || h.direction == HabitDirection.bad;
              goal = isLimitGoal ? HabitGoal.limit(v) : HabitGoal.target(v);
            } else {
              final v = double.tryParse(_goalController.text.replaceAll(',', '.')) ?? 15.0;
              unit = 'мин';
              goal = h.direction == HabitDirection.bad && _limitNotExceed
                  ? HabitGoal.limit(v)
                  : HabitGoal.target(v);
            }

            final now = DateTime.now();
            final baseDate = h.startDate != null
                ? DateTime(h.startDate!.year, h.startDate!.month, h.startDate!.day)
                : DateTime(now.year, now.month, now.day);

            DateTime? startDate;
            DateTime? endDate = _endDate;
            List<int> repeatDays;

            if (_isOneTime) {
              startDate = baseDate;
              endDate = baseDate;
              repeatDays = const [];
            } else {
              startDate = baseDate;
              endDate ??= baseDate.add(const Duration(days: 30));
              if (_repeatWeekdays.isEmpty) {
                repeatDays = const [1, 2, 3, 4, 5, 6, 7];
              } else {
                repeatDays = _repeatWeekdays.toList()..sort();
              }
            }

            Navigator.of(context).pop(Habit(
              id: h.id,
              name: name,
              direction: h.direction,
              measurement: h.measurement,
              goal: goal,
              color: _color,
              icon: _icon,
              unit: unit,
              repeatDays: repeatDays,
              isActive: h.isActive,
              reminder: _reminder,
              startTime: h.startTime,
              startDate: startDate,
              endDate: endDate,
            ));
          },
          child: Text(l.saveButton),
        ),
      ],
    );
  }

  Widget _buildGoalSection(ThemeData theme, Habit h, bool isBinary) {
    if (isBinary) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Количество повторений за день (опционально)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Сколько раз в день?',
              hintText: 'Например: 1',
              suffixText: 'раз',
            ),
          ),
        ],
      );
    }

    final isTimed = h.measurement == HabitMeasurement.timed;
    final isBad = h.direction == HabitDirection.bad;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isTimed
              ? 'Укажите желаемое время'
              : (isBad ? 'Укажите ограничение для привычки' : 'Укажите целевое количество'),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _goalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isTimed ? 'Минут в день' : (isBad ? 'Лимит' : 'Цель'),
            suffixText: isTimed
                ? 'мин'
                : (_unitController.text.isEmpty ? 'раз' : _unitController.text),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (!isTimed) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _unitController,
            decoration: const InputDecoration(
              labelText: 'Единицы счёта',
              hintText: 'раз, км, страниц',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _limitNotExceed,
            onChanged: (v) => setState(() => _limitNotExceed = v ?? true),
            title: const Text('Не превышать это значение'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _buildReminderSection(ThemeData theme, AppLocalizations l) {
    final text = _reminder != null
        ? _reminder!.format(context)
        : 'Нет напоминания';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.notifications_outlined),
      title: Text('${l.reminderLabel} (опционально)'),
      subtitle: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: _reminder != null
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _reminder = null),
            )
          : null,
      onTap: () async {
        final initial = _reminder ?? TimeOfDay.now();
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null && mounted) {
          setState(() => _reminder = picked);
        }
      },
    );
  }

  Widget _buildScheduleSection(ThemeData theme) {
    final weekdayLabels = const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Частота',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        RadioListTile<bool>(
          value: true,
          groupValue: _isOneTime,
          onChanged: (v) => setState(() => _isOneTime = v ?? false),
          title: const Text('Одноразовое событие'),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<bool>(
          value: false,
          groupValue: _isOneTime,
          onChanged: (v) => setState(() => _isOneTime = v ?? false),
          title: const Text('Повторяемое'),
          subtitle: const Text('Как в будильнике'),
          contentPadding: EdgeInsets.zero,
        ),
        if (!_isOneTime) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final selected = _repeatWeekdays.contains(weekday);
              return ChoiceChip(
                label: Text(weekdayLabels[index]),
                selected: selected,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _repeatWeekdays.add(weekday);
                    } else {
                      _repeatWeekdays.remove(weekday);
                    }
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _repeatWeekdays
                      ..clear()
                      ..addAll({1, 2, 3, 4, 5});
                  });
                },
                child: const Text('Будни'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _repeatWeekdays
                      ..clear()
                      ..addAll({6, 7});
                  });
                },
                child: const Text('Выходные'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _repeatWeekdays
                      ..clear()
                      ..addAll({1, 2, 3, 4, 5, 6, 7});
                  });
                },
                child: const Text('Каждый день'),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() => _repeatWeekdays.clear());
              },
              child: const Text('Очистить дни'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Активна с даты начала до',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: const Text('Дата окончания привычки'),
            subtitle: Builder(builder: (context) {
              final start = widget.habit.startDate ??
                  DateTime.now();
              final startStr =
                  '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}';
              final endDate = _endDate ??
                  start.add(const Duration(days: 30));
              final endStr =
                  '${endDate.day.toString().padLeft(2, '0')}.${endDate.month.toString().padLeft(2, '0')}.${endDate.year}';
              final text = 'С $startStr по $endStr';
              return Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }),
            onTap: () async {
              final base = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? base.add(const Duration(days: 30)),
                firstDate: base,
                lastDate: base.add(const Duration(days: 365 * 5)),
              );
              if (picked != null && mounted) {
                setState(() {
                  _endDate = DateTime(picked.year, picked.month, picked.day);
                });
              }
            },
          ),
        ],
      ],
    );
  }
}
