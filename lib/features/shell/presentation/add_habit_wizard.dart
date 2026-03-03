import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';
import '../../../../l10n/app_localizations.dart';

/// Онбординг создания привычки:
/// 1) Направление → 2) Название/иконка/цвет → 3) Тип + цель/напоминание → 4) Частота.
class AddHabitWizard extends StatefulWidget {
  const AddHabitWizard({
    super.key,
    this.initialDate,
    this.initialDirection,
    this.initialMeasurement,
    this.startStep = 1,
    this.isEventMode = false,
  });

  /// Дата, к которой пользователь сейчас привязан (выбрана на главном экране).
  /// Используется для одноразовых событий и даты старта повторяющихся.
  final DateTime? initialDate;

   /// Предзаполненное направление (для специальных флоу).
  final HabitDirection? initialDirection;

  /// Предзаполненный тип измерения (для специальных флоу).
  final HabitMeasurement? initialMeasurement;

  /// Стартовый шаг визарда (по умолчанию 1).
  final int startStep;

  /// Режим «события»: без выбора характера и типа, всегда хороший ритуал.
  final bool isEventMode;

  @override
  State<AddHabitWizard> createState() => _AddHabitWizardState();
}

class _AddHabitWizardState extends State<AddHabitWizard> {
  late int _step;

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
  DateTime? _startDate;
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
  void initState() {
    super.initState();
    _direction = widget.initialDirection;
    _measurement = widget.initialMeasurement;
    _step = widget.startStep;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_canGoNext) return;
    if (widget.isEventMode && _step == 2) {
      // В режиме событий пропускаем шаг выбора типа.
      setState(() => _step = 4);
      return;
    }
    final maxStep = widget.isEventMode ? 4 : 3;
    if (_step < maxStep) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() {
    if (widget.isEventMode) {
      // В режиме событий возвращаемся сразу к закрытию с шага описания.
      if (_step <= 2) {
        Navigator.of(context).pop();
      } else {
        setState(() => _step = 2);
      }
    } else {
      if (_step > 1) {
        setState(() => _step--);
      } else {
        Navigator.of(context).pop();
      }
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
      // Ритуал всегда бинарный: только «сделал / не сделал», без числовой цели.
      goal = const HabitGoal.noGoal();
      unit = null;
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
    final initialBaseDate = widget.initialDate != null
        ? DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day)
        : DateTime(now.year, now.month, now.day);
    final baseStartDate = _startDate ?? initialBaseDate;

    DateTime? startDate;
    DateTime? endDate;
    List<int> repeatDays;

    if (_isOneTime) {
      startDate = initialBaseDate;
      endDate = initialBaseDate;
      repeatDays = const [];
    } else {
      startDate = baseStartDate;
      endDate = _endDate ?? baseStartDate.add(const Duration(days: 7));
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
      isEvent: widget.isEventMode,
    );

    Navigator.of(context).pop(habit);
  }

  bool get _canGoNext {
    switch (_step) {
      case 1:
        // Шаг 1 всегда про название и оформление.
        return _nameController.text.trim().isNotEmpty;
      case 2:
        // Для событий на шаге 2 тоже только описание.
        if (widget.isEventMode) {
          return _nameController.text.trim().isNotEmpty;
        }
        // Для привычек на шаге 2 выбираем тип и задаём цель.
        if (_measurement == null) return false;
        if (_measurement == HabitMeasurement.binary) return true;
        final v = _goalValue ??
            (_goalController.text.isNotEmpty
                ? double.tryParse(_goalController.text.replaceAll(',', '.'))
                : null);
        return v != null && v > 0;
      case 3:
        // Частота: дополнительных валидаций пока нет.
        return true;
      case 4:
        // До шага 4 доходим только в режиме событий.
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
                  // Для привычек: 1 — имя, 2 — тип, 3 — частота.
                  // Для событий: стартуем сразу со 2-го шага (описание), 4 — частота.
                  1 => _buildStepBasic(theme),
                  2 => widget.isEventMode
                      ? _buildStepBasic(theme)
                      : _buildStepTypeAndGoal(context, theme, l),
                  3 => widget.isEventMode
                      ? const SizedBox.shrink()
                      : _buildStepFrequency(theme),
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
        return widget.isEventMode ? 'Описание события' : 'Шаг 1: Описание';
      case 2:
        return widget.isEventMode ? 'Описание события' : 'Шаг 2: Тип';
      case 3:
        return 'Шаг 3: Частота';
      case 4:
        // В режиме событий это второй шаг: описание → частота.
        return widget.isEventMode ? 'Шаг 2: Частота' : 'Шаг 4: Частота';
      default:
        return 'Новая привычка';
    }
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
  ) {
    if (widget.isEventMode) {
      // Для событий тип заранее фиксирован как ритуал.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Тип события',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Событие создаётся как одноразовый ритуал: просто отметьте, произошло оно или нет.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    // Во вкладке привычек ритуал (binary) убираем — он живёт во вкладке событий.
    // Пользователь видит только типы, а мы внутри помечаем хорошую/плохую привычку.
    final options = [
      _MeasurementOption(
        type: HabitMeasurement.timed,
        direction: HabitDirection.good,
        icon: Icons.timer_outlined,
        title: 'Таймер',
        subtitle: 'Ограничение по времени',
      ),
      _MeasurementOption(
        type: HabitMeasurement.counted,
        direction: HabitDirection.good,
        icon: Icons.format_list_numbered,
        title: 'Счётчик',
        subtitle: 'Сделать N раз',
      ),
      _MeasurementOption(
        type: HabitMeasurement.timed,
        direction: HabitDirection.bad,
        icon: Icons.hourglass_empty,
        title: 'Ограничение по времени',
        subtitle: 'Не больше N минут',
      ),
      _MeasurementOption(
        type: HabitMeasurement.counted,
        direction: HabitDirection.bad,
        icon: Icons.trending_down,
        title: 'Лимит',
        subtitle: 'Не превысить N раз',
      ),
    ];

    final isGood = _direction != HabitDirection.bad;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Тип привычки',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Выберите тип отслеживания.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...options.map((o) {
          final selected = _measurement == o.type && _direction == o.direction;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: selected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => setState(() {
                  _measurement = o.type;
                  _direction = o.direction;
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
                      if (selected)
                        Icon(Icons.check_circle, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
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
              'Для ритуала не задаётся числовая цель — просто отмечайте выполнение один раз за день.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
    final startDate = _startDate ?? baseDate;

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
          const SizedBox(height: 8),
          Text(
            'Период действия',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Дата начала'),
            subtitle: Text(
              '${startDate.day.toString().padLeft(2, '0')}.${startDate.month.toString().padLeft(2, '0')}.${startDate.year}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: baseDate.subtract(const Duration(days: 365 * 5)),
                lastDate: baseDate.add(const Duration(days: 365 * 5)),
              );
              if (picked != null && mounted) {
                setState(() {
                  _startDate = DateTime(picked.year, picked.month, picked.day);
                  // Если дата окончания раньше старта — сдвигаем конец на месяц вперёд.
                  if (_endDate != null && _endDate!.isBefore(_startDate!)) {
                    _endDate = _startDate!.add(const Duration(days: 30));
                  }
                });
              }
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                setState(() {
                  _repeatWeekdays.clear();
                });
              },
              child: const Text('Очистить дни'),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: const Text('Дата окончания'),
            subtitle: Text(
              _endDate != null
                  ? '${_endDate!.day.toString().padLeft(2, '0')}.${_endDate!.month.toString().padLeft(2, '0')}.${_endDate!.year}'
                  : '${startDate.add(const Duration(days: 7)).day.toString().padLeft(2, '0')}.${startDate.add(const Duration(days: 7)).month.toString().padLeft(2, '0')}.${startDate.add(const Duration(days: 7)).year}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? startDate.add(const Duration(days: 7)),
                firstDate: startDate,
                lastDate: startDate.add(const Duration(days: 365 * 5)),
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
    required this.direction,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final HabitMeasurement type;
  final HabitDirection direction;
  final IconData icon;
  final String title;
  final String subtitle;
}
