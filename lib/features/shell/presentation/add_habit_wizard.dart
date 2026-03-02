import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';
import '../../../../l10n/app_localizations.dart';

/// Онбординг создания привычки: 4 шага — Базовое → Направление → Тип измерения → Цель.
class AddHabitWizard extends StatefulWidget {
  const AddHabitWizard({super.key});

  @override
  State<AddHabitWizard> createState() => _AddHabitWizardState();
}

class _AddHabitWizardState extends State<AddHabitWizard> {
  int _step = 1;

  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  IconData _icon = Icons.star_rounded;
  Color _color = Colors.green;
  HabitDirection? _direction;
  HabitMeasurement? _measurement;
  double? _goalValue;
  String _goalUnit = '';

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
    super.dispose();
  }

  void _next() {
    if (_step == 2 && _direction == null) return;
    if (_step == 3 && _measurement == null) return;
    if (_step == 3 && _measurement == HabitMeasurement.binary) {
      _save();
      return;
    }
    if (_step == 4) {
      _save();
      return;
    }
    setState(() {
      _step++;
      if (_step == 4) {
        if (_goalValue == null) {
          _goalValue = _measurement == HabitMeasurement.timed ? 15.0 : 5.0;
          _goalUnit = _measurement == HabitMeasurement.timed ? 'мин' : 'раз';
          _goalController.text = _goalValue!.toInt().toString();
        }
      }
    });
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

    HabitGoal goal;
    String? unit;
    if (measurement == HabitMeasurement.binary) {
      goal = const HabitGoal.noGoal();
    } else {
      final v = _goalValue ?? 1.0;
      unit = _goalUnit.isNotEmpty ? _goalUnit : (measurement == HabitMeasurement.timed ? 'мин' : 'раз');
      goal = direction == HabitDirection.good
          ? HabitGoal.target(v)
          : HabitGoal.limit(v);
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
      repeatDays: [],
      isActive: true,
    );
    Navigator.of(context).pop(habit);
  }

  bool get _canGoNext {
    switch (_step) {
      case 1:
        return _nameController.text.trim().isNotEmpty;
      case 2:
        return _direction != null;
      case 3:
        return _measurement != null;
      case 4:
        if (_measurement == HabitMeasurement.binary) return true;
        return _goalValue != null && (_goalValue ?? 0) > 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isGood = _direction == HabitDirection.good;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
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
                child: _step == 1
                    ? _buildStep1(theme)
                    : _step == 2
                        ? _buildStep2(theme, l)
                        : _step == 3
                            ? _buildStep3(theme, l, isGood)
                            : _buildStep4(theme, l, isGood),
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
                    child: Text(_step == 4 || (_step == 3 && _measurement == HabitMeasurement.binary) ? l.saveButton : 'Далее'),
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
      case 1: return 'Шаг 1: Базовое';
      case 2: return 'Шаг 2: Направление';
      case 3: return 'Шаг 3: Тип измерения';
      case 4: return 'Шаг 4: Цель';
      default: return 'Новая привычка';
    }
  }

  Widget _buildStep1(ThemeData theme) {
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

  Widget _buildStep2(ThemeData theme, AppLocalizations l) {
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
                onTap: () => setState(() => _direction = HabitDirection.good),
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
                onTap: () => setState(() => _direction = HabitDirection.bad),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3(ThemeData theme, AppLocalizations l, bool isGood) {
    final options = isGood
        ? [
            _MeasurementOption(
              type: HabitMeasurement.binary,
              icon: Icons.check_circle_outline,
              title: 'Ритуал',
              subtitle: 'Просто сделать / не сделать',
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
              title: 'Искушение',
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
              title: 'Ограничитель времени',
              subtitle: 'Не больше N минут',
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isGood ? 'Как вы хотите отслеживать привычку?' : 'Как вы хотите ограничивать привычку?',
          style: theme.textTheme.bodyLarge?.copyWith(
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
                  onTap: () => setState(() => _measurement = o.type),
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
      ],
    );
  }

  Widget _buildStep4(ThemeData theme, AppLocalizations l, bool isGood) {
    if (_measurement == HabitMeasurement.binary) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Для ритуала и искушения цель не задаётся — просто отмечайте выполнение или срыв.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final isTimed = _measurement == HabitMeasurement.timed;
    final label = isTimed ? 'Минут в день' : (isGood ? 'Сколько раз сделать?' : 'Лимит (не больше скольких раз?)');
    final hint = isTimed ? '20' : '5';
    final defaultUnit = isTimed ? 'мин' : 'раз';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isGood ? 'Целевое значение' : 'Лимит',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _goalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixText: _goalUnit.isEmpty ? defaultUnit : _goalUnit,
          ),
          onChanged: (s) {
            final v = double.tryParse(s.replaceAll(',', '.'));
            setState(() {
              _goalValue = v;
              if (_goalUnit.isEmpty) _goalUnit = defaultUnit;
            });
          },
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Единица (опционально)',
            hintText: 'раз, мин, стак., шт',
          ),
          onChanged: (s) => setState(() => _goalUnit = s.trim().isEmpty ? defaultUnit : s),
        ),
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
