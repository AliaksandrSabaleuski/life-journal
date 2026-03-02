import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';
import '../../../../l10n/app_localizations.dart';

/// Онбординг создания привычки:
/// 1) Направление → 2) Название/иконка/цвет → 3) Тип + цель/напоминание → 4) Частота.
class AddHabitWizard extends StatefulWidget {
  const AddHabitWizard({
    super.key,
    this.initialDate,
  });

  /// Дата, к которой пользователь сейчас привязан (выбрана на главном экране).
  /// Используется для одноразовых событий и даты старта повторяющихся.
  final DateTime? initialDate;

  @override
  State<AddHabitWizard> createState() => _AddHabitWizardState();
}

class _AddHabitWizardState extends State<AddHabitWizard> {
  int _step = 1;

  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _unitController = TextEditingController();

  IconData _icon = Icons.star_rounded;
  Color _color = Colors.green;

  HabitDirection? _direction;
  HabitMeasurement? _measurement;

  double? _goalValue;
  String _goalUnit = '';
  bool _limitNotExceed = true;

  TimeOfDay? _reminder;

  bool _isOneTime = false;
  final Set<int> _repeatWeekdays = {1, 2, 3, 4, 5, 6, 7};
  DateTime? _endDate;

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
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_canGoNext) return;
    if (_step < 4) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final direction = _direction ?? HabitDirection.good;
    final measurement = _measurement ?? HabitMeasurement.binary;

    // Цель и единица измерения.
    HabitGoal goal;
    String? unit;

    if (measurement == HabitMeasurement.binary) {
      // Для ритуала можно задать кол-во повторений, но сама отметка остаётся бинарной.
      if (_goalValue != null && _goalValue! > 0) {
        goal = HabitGoal.target(_goalValue!);
        unit = _goalUnit.isNotEmpty ? _goalUnit : 'раз';
      } else {
        goal = const HabitGoal.noGoal();
      }
    } else if (measurement == HabitMeasurement.counted) {
      final v = (_goalValue ?? double.tryParse(_goalController.text.replaceAll(',', '.'))) ?? 1.0;
      unit = _unitController.text.trim().isNotEmpty
          ? _unitController.text.trim()
          : (_goalUnit.isNotEmpty ? _goalUnit : 'раз');
      final isLimitGoal = _limitNotExceed || direction == HabitDirection.bad;
      goal = isLimitGoal ? HabitGoal.limit(v) : HabitGoal.target(v);
    } else {
      // timed
      final v = (_goalValue ?? double.tryParse(_goalController.text.replaceAll(',', '.'))) ?? 15.0;
      unit = 'мин';
      goal = direction == HabitDirection.bad && _limitNotExceed
          ? HabitGoal.limit(v)
          : HabitGoal.target(v);
    }

    // Частота.
    final now = DateTime.now();
    final baseDate = widget.initialDate != null
        ? DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day)
        : DateTime(now.year, now.month, now.day);

    DateTime? startDate;
    DateTime? endDate;
    List<int> repeatDays;

    if (_isOneTime) {
      startDate = baseDate;
      endDate = baseDate;
      repeatDays = const [];
    } else {
      startDate = baseDate;
      endDate = _endDate ?? baseDate.add(const Duration(days: 30));
      if (_repeatWeekdays.isEmpty) {
        repeatDays = const [1, 2, 3, 4, 5, 6, 7];
      } else {
        repeatDays = _repeatWeekdays.toList()..sort();
      }
    }

    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      direction: direction,
      measurement: measurement,
      goal: goal,
      color: _color,
      icon: _icon,
      unit: unit,
      repeatDays: repeatDays,
      isActive: true,
      reminder: _reminder,
      startDate: startDate,
      endDate: endDate,
    );

    Navigator.of(context).pop(habit);
  }

  bool get _canGoNext {
    switch (_step) {
      case 1:
        return _direction != null;
      case 2:
        return _nameController.text.trim().isNotEmpty;
      case 3:
        if (_measurement == null) return false;
        if (_measurement == HabitMeasurement.binary) return true;
        final v = _goalValue ??
            (_goalController.text.isNotEmpty
                ? double.tryParse(_goalController.text.replaceAll(',', '.'))
                : null);
        return v != null && v > 0;
      case 4:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isGood = _direction != HabitDirection.bad;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(_stepTitle),
              centerTitle: true,
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: switch (_step) {
                  1 => _buildStepDirection(theme, l),
                  2 => _buildStepBasic(theme),
                  3 => _buildStepTypeAndGoal(context, theme, l, isGood),
                  4 => _buildStepFrequency(theme),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _back,
                    child: Text(_step > 1 ? 'Назад' : l.cancelButton),
                  ),
                  FilledButton(
                    onPressed: _canGoNext ? _next : null,
                    child: Text(_step == 4 ? l.saveButton : 'Далее'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 1:
        return 'Шаг 1: Характер';
      case 2:
        return 'Шаг 2: Описание';
      case 3:
        return 'Шаг 3: Тип и цель';
      case 4:
        return 'Шаг 4: Частота';
      default:
        return 'Новая привычка';
    }
  }

  Widget _buildStepDirection(ThemeData theme, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Выберите направление привычки',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _DirectionCard(
                icon: Icons.thumb_up_rounded,
                label: l.goodHabitLabel,
                subtitle: 'Привычка, которую хотите внедрить',
                color: Colors.green,
                selected: _direction == HabitDirection.good,
                onTap: () => setState(() {
                  _direction = HabitDirection.good;
                  _step = 2;
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DirectionCard(
                icon: Icons.thumb_down_rounded,
                label: l.badHabitLabel,
                subtitle: 'Привычка, от которой хотите избавиться',
                color: Colors.orange,
                selected: _direction == HabitDirection.bad,
                onTap: () => setState(() {
                  _direction = HabitDirection.bad;
                  _step = 2;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepBasic(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Название привычки',
            hintText: 'Например: Заправить кровать',
          ),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
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
        const SizedBox(height: 20),
        Text('Цвет (опционально)', style: theme.textTheme.titleSmall),
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
      ],
    );
  }

  Widget _buildStepTypeAndGoal(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l,
    bool isGood,
  ) {
    final options = isGood
        ? [
            _MeasurementOption(
              type: HabitMeasurement.binary,
              icon: Icons.auto_awesome,
              title: 'Ритуал',
              subtitle: 'Сделать / не сделать',
            ),
            _MeasurementOption(
              type: HabitMeasurement.counted,
              icon: Icons.format_list_numbered,
              title: 'Счётчик',
              subtitle: 'Сделать N раз',
            ),
            _MeasurementOption(
              type: HabitMeasurement.timed,
              icon: Icons.timer_outlined,
              title: 'Таймер',
              subtitle: 'Делать N минут',
            ),
          ]
        : [
            _MeasurementOption(
              type: HabitMeasurement.binary,
              icon: Icons.warning_amber_rounded,
              title: 'Ритуал',
              subtitle: 'Удержаться / сорваться',
            ),
            _MeasurementOption(
              type: HabitMeasurement.counted,
              icon: Icons.trending_down,
              title: 'Лимит',
              subtitle: 'Не превысить N раз',
            ),
            _MeasurementOption(
              type: HabitMeasurement.timed,
              icon: Icons.hourglass_empty,
              title: 'Таймер',
              subtitle: 'Время в минутах',
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Тип привычки',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          isGood ? 'Выберите, как отслеживать привычку.' : 'Выберите, как ограничивать привычку.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...options.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: _measurement == o.type
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => setState(() {
                    _measurement = o.type;
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(o.icon, color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                o.subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_measurement == o.type)
                          Icon(Icons.check_circle, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            )),
        if (_measurement != null) ...[
          const SizedBox(height: 24),
          _buildMeasurementDetails(theme, isGood),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildReminderPicker(context, theme, l),
        ],
      ],
    );
  }

  Widget _buildMeasurementDetails(ThemeData theme, bool isGood) {
    switch (_measurement) {
      case HabitMeasurement.binary:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Количество повторений за день (опционально)',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
              onChanged: (s) {
                final v = double.tryParse(s.replaceAll(',', '.'));
                setState(() {
                  _goalValue = v;
                  _goalUnit = 'раз';
                });
              },
            ),
          ],
        );
      case HabitMeasurement.counted:
        final isBad = !isGood;
        final label = isBad ? 'Укажите ограничение для привычки' : 'Укажите целевое количество';
        final hint = isBad ? 'Не больше скольких раз?' : 'Например: 5';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isBad ? 'Лимит' : 'Цель',
                hintText: hint,
                suffixText: _unitController.text.isEmpty ? 'раз' : _unitController.text,
              ),
              onChanged: (s) {
                final v = double.tryParse(s.replaceAll(',', '.'));
                setState(() {
                  _goalValue = v;
                });
              },
            ),
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
        );
      case HabitMeasurement.timed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Укажите желаемое время',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Минут в день',
                hintText: 'Например: 20',
                suffixText: 'мин',
              ),
              onChanged: (s) {
                final v = double.tryParse(s.replaceAll(',', '.'));
                setState(() {
                  _goalValue = v;
                });
              },
            ),
          ],
        );
      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReminderPicker(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l,
  ) {
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

  Widget _buildStepFrequency(ThemeData theme) {
    final weekdayLabels = const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final now = DateTime.now();
    final baseDate = widget.initialDate != null
        ? DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day)
        : DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Частота',
          style: theme.textTheme.titleMedium,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final weekday = index + 1; // 1 — пн, 7 — вс
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
          const SizedBox(height: 12),
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
                setState(() {
                  _repeatWeekdays.clear();
                });
              },
              child: const Text('Очистить дни'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Активна с выбранной даты до',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: const Text('Дата окончания привычки'),
            subtitle: Builder(builder: (context) {
              final startStr =
                  '${baseDate.day.toString().padLeft(2, '0')}.${baseDate.month.toString().padLeft(2, '0')}.${baseDate.year}';
              final endDate = _endDate ?? baseDate.add(const Duration(days: 30));
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
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? baseDate.add(const Duration(days: 30)),
                firstDate: baseDate,
                lastDate: baseDate.add(const Duration(days: 365 * 5)),
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

class _DirectionCard extends StatelessWidget {
  const _DirectionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool selected;
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
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(Icons.check_circle, color: color, size: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasurementOption {
  const _MeasurementOption({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final HabitMeasurement type;
  final IconData icon;
  final String title;
  final String subtitle;
}
