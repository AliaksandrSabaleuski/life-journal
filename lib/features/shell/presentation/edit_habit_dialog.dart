import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/catalog/color_registry.dart';
import '../../../../core/catalog/icon_registry.dart';
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
  final ScrollController _iconScrollController = ScrollController();
  final ScrollController _colorScrollController = ScrollController();
  late IconData _icon;
  late Color _color;

  late bool _isOneTime;
  late Set<int> _repeatWeekdays;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _reminder;

  List<Color> get _colors {
    final list = List<Color>.from(ColorRegistry.allColors);
    if (!list.contains(_color)) list.insert(0, _color);
    return list;
  }

  List<IconData> get _icons {
    final list = List<IconData>.from(IconRegistry.allIcons);
    if (!list.any((i) => i.codePoint == _icon.codePoint)) list.insert(0, _icon);
    return list;
  }

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

    _reminder = h.reminder;

    final start = h.startDate;
    final end = h.endDate;
    final sameDay = start != null &&
        end != null &&
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    _isOneTime = h.repeatDays.isEmpty && sameDay;
    _startDate = start;
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
    _iconScrollController.dispose();
    _colorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final h = widget.habit;
    final isBinary = h.measurement == HabitMeasurement.binary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Редактировать привычку',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название привычки',
                        hintText: 'Например: Стакан воды',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),
                    Text('Иконка', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: ClipRect(
                        child: Scrollbar(
                        controller: _iconScrollController,
                        thumbVisibility: false,
                        trackVisibility: false,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            },
                          ),
                          child: ListView.separated(
                            controller: _iconScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            itemCount: _icons.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final icon = _icons[index];
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
                          },
                        ),
                      ),
                    ),
                    ),
                    ),
                    const SizedBox(height: 20),
                    Text('Цвет (опционально)', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ClipRect(
                        child: Scrollbar(
                        controller: _colorScrollController,
                        thumbVisibility: false,
                        trackVisibility: false,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            },
                          ),
                          child: ListView.separated(
                            controller: _colorScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            itemCount: _colors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final c = _colors[index];
                            final selected = _color == c;
                            return GestureDetector(
                              onTap: () => setState(() => _color = c),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? theme.colorScheme.primary : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    ),
                    ),
                    const SizedBox(height: 20),
                    _buildGoalSection(theme, h, isBinary),
                    const SizedBox(height: 16),
                    _buildReminderSection(theme, l),
                    const SizedBox(height: 16),
                    _buildScheduleSection(theme),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      final habit = widget.habit;
                      final base = widget.selectedDate != null
                          ? DateTime(
                              widget.selectedDate!.year,
                              widget.selectedDate!.month,
                              widget.selectedDate!.day,
                            )
                          : DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                            );

                      final newEnd = base.subtract(const Duration(days: 1));

                      DateTime? startDate = habit.startDate;
                      if (startDate != null && newEnd.isBefore(startDate)) {
                        Navigator.of(context).pop(
                          habit.copyWith(isActive: false),
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
                          habit.copyWith(endDate: newEnd),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Удалить'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.cancelButton),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      HabitGoal goal;
                      String? unit;

                      if (isBinary) {
                        goal = const HabitGoal.noGoal();
                        unit = null;
                      } else if (h.measurement == HabitMeasurement.counted) {
                        final v = double.tryParse(_goalController.text.replaceAll(',', '.')) ?? 1.0;
                        unit = _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'раз';
                        goal = HabitGoal.target(v);
                      } else {
                        final v = double.tryParse(_goalController.text.replaceAll(',', '.')) ?? 15.0;
                        unit = 'мин';
                        goal = HabitGoal.target(v);
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
                        startDate = _startDate ?? baseDate;
                        endDate ??= baseDate.add(const Duration(days: 30));
                        if (_repeatWeekdays.isEmpty) {
                          repeatDays = const [1, 2, 3, 4, 5, 6, 7];
                        } else {
                          repeatDays = _repeatWeekdays.toList()..sort();
                        }
                      }

                      Navigator.of(context).pop(
                        Habit(
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
                          isEvent: h.isEvent,
                          templateId: h.templateId,
                        ),
                      );
                    },
                    child: Text(l.saveButton),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSection(ThemeData theme, Habit h, bool isBinary) {
    if (isBinary) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Для ритуала не задаётся числовая цель — просто отмечайте выполнение один раз за день.',
            style: theme.textTheme.titleSmall,
          ),
        ],
      );
    }

    final isTimed = h.measurement == HabitMeasurement.timed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isTimed
              ? 'Укажите желаемое время'
              : 'Укажите целевое количество',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _goalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isTimed ? 'Минут в день' : 'Цель',
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
    final start = _startDate ?? widget.habit.startDate ?? DateTime.now();

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
          Text(
            'Период действия',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Дата начала'),
            subtitle: Text(
              '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () async {
              final base = widget.habit.startDate ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: start,
                firstDate: base.subtract(const Duration(days: 365 * 5)),
                lastDate: base.add(const Duration(days: 365 * 5)),
              );
              if (picked != null && mounted) {
                setState(() {
                  _startDate = DateTime(picked.year, picked.month, picked.day);
                  if (_endDate != null && _endDate!.isBefore(_startDate!)) {
                    _endDate = _startDate!.add(const Duration(days: 30));
                  }
                });
              }
            },
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _repeatWeekdays
                      ..clear()
                      ..addAll({1, 2, 3, 4, 5});
                  });
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
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
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
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
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
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
              final base = start;
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
