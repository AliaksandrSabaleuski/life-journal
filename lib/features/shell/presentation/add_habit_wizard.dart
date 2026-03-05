import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/catalog/color_registry.dart';
import '../../../../core/catalog/habit_template.dart';
import '../../../../core/catalog/habits_catalog.dart';
import '../../../../core/catalog/icon_registry.dart';
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
    this.startStep = 0,
    this.isEventMode = false,
  });

  /// Дата, к которой пользователь сейчас привязан (выбрана на главном экране).
  /// Используется для одноразовых событий и даты старта повторяющихся.
  final DateTime? initialDate;

   /// Предзаполненное направление (для специальных флоу).
  final HabitDirection? initialDirection;

  /// Предзаполненный тип измерения (для специальных флоу).
  final HabitMeasurement? initialMeasurement;

  /// Стартовый шаг визарда (по умолчанию 0 — выбор источника).
  final int startStep;

  /// Режим «события»: без выбора характера и типа, всегда хороший ритуал.
  final bool isEventMode;

  @override
  State<AddHabitWizard> createState() => _AddHabitWizardState();
}

class _AddHabitWizardState extends State<AddHabitWizard> {
  late int _step;

  HabitsCatalog? _catalog;
  String? _selectedTemplateId;
  bool _isCatalogLoading = false;
  bool _lockTypeSelection = false;

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

  static const _defaultStepForHabit = 1;
  static const _defaultStepForEvent = 2;

  CreationSource _source = CreationSource.custom;

  @override
  void initState() {
    super.initState();
    _direction = widget.initialDirection;
    _measurement = widget.initialMeasurement;
    _step = widget.startStep;
    // По умолчанию для событий выбираем преднастроенные события,
    // для привычек — преднастроенные привычки.
    _source =
        widget.isEventMode ? CreationSource.presetEvent : CreationSource.presetHabit;
    _loadCatalog();
  }

  List<HabitTemplate> _templatesForCurrentSource() {
    final catalog = _catalog;
    if (catalog == null) return const [];
    switch (_source) {
      case CreationSource.presetHabit:
        return catalog.habits.toList();
      case CreationSource.presetEvent:
        return catalog.events.toList();
      case CreationSource.custom:
        return const [];
    }
  }

  Widget _buildStepSource(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l,
  ) {
    final isEvent = widget.isEventMode;
    final presets = _templatesForCurrentSource();

    final options = <Widget>[];

    if (!isEvent) {
      options.add(
        RadioListTile<CreationSource>(
          value: CreationSource.presetHabit,
          groupValue: _source,
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _source = v;
              _lockTypeSelection = false;
              _selectedTemplateId = null;
              _ensurePresetSelectedForSource();
            });
          },
          title: const Text('Преднастроенные привычки'),
          subtitle: const Text('Выбрать из каталога шаблонов'),
          contentPadding: EdgeInsets.zero,
        ),
      );
      options.add(
        RadioListTile<CreationSource>(
          value: CreationSource.presetEvent,
          groupValue: _source,
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _source = v;
              _lockTypeSelection = false;
              _selectedTemplateId = null;
              _ensurePresetSelectedForSource();
            });
          },
          title: const Text('Преднастроенные события'),
          subtitle: const Text('События из каталога'),
          contentPadding: EdgeInsets.zero,
        ),
      );
    } else {
      options.add(
        RadioListTile<CreationSource>(
          value: CreationSource.presetEvent,
          groupValue: _source,
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _source = v;
              _lockTypeSelection = false;
              _selectedTemplateId = null;
              _ensurePresetSelectedForSource();
            });
          },
          title: const Text('Преднастроенные события'),
          subtitle: const Text('События из каталога'),
          contentPadding: EdgeInsets.zero,
        ),
      );
    }

    options.add(
      RadioListTile<CreationSource>(
        value: CreationSource.custom,
        groupValue: _source,
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _source = v;
            _lockTypeSelection = false;
            _selectedTemplateId = null;
            _ensurePresetSelectedForSource();
          });
        },
        title: const Text('Свое'),
        subtitle: const Text('Настроить вручную (текущий флоу)'),
        contentPadding: EdgeInsets.zero,
      ),
    );

    final dropdown = (_source == CreationSource.custom)
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isCatalogLoading)
                const Center(child: CircularProgressIndicator())
              else if (presets.isEmpty)
                const Text('Каталог пуст — добавьте шаблоны в конфиг.')
              else
                DropdownButtonFormField<String>(
                  key: ValueKey(_source),
                  value: _selectedTemplateId,
                  items: presets
                      .map(
                        (t) => DropdownMenuItem<String>(
                          value: t.templateId,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (IconRegistry.byKey(t.iconKey) != null) ...[
                                Icon(
                                  IconRegistry.byKey(t.iconKey),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  t.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _selectedTemplateId = v);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Выберите из преднастроенных',
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Выберите из преднастроенных',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        dropdown,
        const SizedBox(height: 8),
        Text(
          'Или выберите способ создания ниже. Можно взять готовый шаблон из каталога или настроить свою привычку с нуля.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...options,
      ],
    );
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
    if (_step == 0) {
      if (_source == CreationSource.custom) {
        setState(() {
          _step = widget.isEventMode ? _defaultStepForEvent : _defaultStepForHabit;
        });
        return;
      }

      // Для преднастроенных привычек даём пользователю
      // настроить только число, напоминание и периодичность,
      // поэтому сразу перескакиваем на шаг 2 (тип/цель) и дальше на частоту.
      if (_source == CreationSource.presetHabit) {
        final templates = _templatesForCurrentSource();
        if (templates.isEmpty) return;
        final template = _resolveCurrentTemplate(templates);
        _applyPresetToState(template);
        setState(() {
          _lockTypeSelection = true;
          _step = 2; // пропускаем шаг 1: сразу к цели/напоминанию
        });
        return;
      }

      // Для преднастроенных событий: применяем пресет и сразу
      // открываем шаг с периодом действия (без шага количества).
      if (_source == CreationSource.presetEvent) {
        final templates = _templatesForCurrentSource();
        if (templates.isEmpty) return;
        final template = _resolveCurrentTemplate(templates);
        _applyPresetToState(template);
        setState(() {
          _step = 4; // сразу к периоду действия
        });
        return;
      }
    }
    if (widget.isEventMode && _step == 2) {
      // В режиме событий пропускаем шаг выбора типа.
      setState(() => _step = 4);
      return;
    }
    final maxStep = widget.isEventMode ? 4 : 3;
    if (_step < maxStep) {
      // Для привычек при выборе одноразового формата пропускаем шаг частоты.
      if (!widget.isEventMode && _step == 2 && _isOneTime) {
        _save();
        return;
      }
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
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

  Future<void> _loadCatalog() async {
    setState(() => _isCatalogLoading = true);
    try {
      final catalog = await HabitsCatalog.loadFromAsset();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _ensurePresetSelectedForSource();
      });
    } finally {
      if (mounted) {
        setState(() => _isCatalogLoading = false);
      }
    }
  }

  void _ensurePresetSelectedForSource() {
    if (_source == CreationSource.custom) {
      _selectedTemplateId = null;
      return;
    }
    final presets = _templatesForCurrentSource();
    if (presets.isEmpty) {
      _selectedTemplateId = null;
      return;
    }
    final hasCurrent =
        _selectedTemplateId != null && presets.any((t) => t.templateId == _selectedTemplateId);
    if (!hasCurrent) {
      _selectedTemplateId = presets.first.templateId;
    }
  }

  void _saveFromPreset() {
    final templates = _templatesForCurrentSource();
    if (templates.isEmpty) return;
    final template = _resolveCurrentTemplate(templates);

    final now = DateTime.now();
    final initialBaseDate = widget.initialDate != null
        ? DateTime(
            widget.initialDate!.year,
            widget.initialDate!.month,
            widget.initialDate!.day,
          )
        : DateTime(now.year, now.month, now.day);

    final color = ColorRegistry.byKey(template.colorKey);
    final icon = IconRegistry.byKey(template.iconKey);

    final habit = template.createInstance(
      instanceId: DateTime.now().millisecondsSinceEpoch.toString(),
      color: color,
      icon: icon,
      startDate: initialBaseDate,
    );

    Navigator.of(context).pop(habit);
  }

  HabitTemplate _resolveCurrentTemplate(List<HabitTemplate> templates) {
    if (templates.isEmpty) {
      throw StateError('No templates available for current source');
    }
    if (_selectedTemplateId == null) {
      return templates.first;
    }
    return templates.firstWhere(
      (t) => t.templateId == _selectedTemplateId,
      orElse: () => templates.first,
    );
  }

  void _applyPresetToState(HabitTemplate template) {
    // Название
    _nameController.text = template.name;

    // Иконка и цвет
    final icon = IconRegistry.byKey(template.iconKey);
    if (icon != null) {
      _icon = icon;
    }
    _color = ColorRegistry.byKey(template.colorKey);

    // Направление и измерение (тип)
    _direction = template.direction;
    _measurement = template.measurement;

    // Цель и единицы
    switch (template.measurement) {
      case HabitMeasurement.binary:
        _goalValue = null;
        _goalController.text = '';
        _unitController.text = '';
        _goalUnit = '';
        _limitNotExceed = template.direction == HabitDirection.bad;
        break;
      case HabitMeasurement.counted:
        final v = template.goal.value ?? 1;
        _goalValue = v;
        _goalController.text = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
        _unitController.text = template.unit ?? '';
        _goalUnit = template.unit ?? '';
        _limitNotExceed = template.goal.kind == HabitGoalKind.limit ||
            template.direction == HabitDirection.bad;
        break;
      case HabitMeasurement.timed:
        final v = template.goal.value ?? 10;
        _goalValue = v;
        _goalController.text = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
        _unitController.text = template.unit ?? 'мин';
        _goalUnit = template.unit ?? 'мин';
        _limitNotExceed = template.goal.kind == HabitGoalKind.limit &&
            template.direction == HabitDirection.bad;
        break;
    }

    // Напоминание: по умолчанию выключено, пользователь включает сам
    _reminder = null;

    // Периодичность
    if (template.repeatDays.isEmpty) {
      _isOneTime = true;
      _repeatWeekdays
        ..clear()
        ..addAll({1, 2, 3, 4, 5, 6, 7});
    } else {
      _isOneTime = false;
      _repeatWeekdays
        ..clear()
        ..addAll(template.repeatDays);
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

    final isEventFlag =
        widget.isEventMode || _source == CreationSource.presetEvent;

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
      isEvent: isEventFlag,
    );

    Navigator.of(context).pop(habit);
  }

  bool get _canGoNext {
    switch (_step) {
      case 0:
        if (_source == CreationSource.custom) return true;
        if (_isCatalogLoading) return false;
        return _templatesForCurrentSource().isNotEmpty;
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
                  0 => _buildStepSource(context, theme, l),
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
                    child: Text(_step > 0 ? 'Назад' : l.cancelButton),
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
      case 0:
        return 'Как создать?';
      case 1:
        return widget.isEventMode ? 'Описание события' : 'Шаг 1: Описание';
      case 2:
        return widget.isEventMode ? 'Описание события' : 'Шаг 2: Тип';
      case 3:
        return 'Период действия';
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
        SizedBox(
          height: 56,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _presetIcons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final icon = _presetIcons[index];
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
        const SizedBox(height: 20),
        Text('Цвет (опционально)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _presetColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final c = _presetColors[index];
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
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTypeAndGoal(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l,
  ) {
    // В онбординге с преднастроенной привычкой тип уже выбран из пресета,
    // поэтому показываем только цель и напоминание, без карточек выбора типа.
    final isPresetLocked = _lockTypeSelection && !widget.isEventMode;
    if (isPresetLocked && _measurement != null) {
      final isGood = _direction != HabitDirection.bad;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMeasurementDetails(theme, isGood),
          const SizedBox(height: 24),
          Text(
            'Формат',
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
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildReminderPicker(context, theme, l),
        ],
      );
    }

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
        final lockUnits = _lockTypeSelection && !widget.isEventMode;
        if (lockUnits) {
          // Пресет: аккуратное компактное поле по центру + подпись единиц.
          final unitsText = _unitController.text.isEmpty ? 'раз' : _unitController.text;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _goalController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                  decoration: InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  onChanged: (s) {
                    final v = double.tryParse(s.replaceAll(',', '.'));
                    setState(() {
                      _goalValue = v;
                    });
                  },
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unitsText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        } else {
          // Обычный флоу: полное управление числом и единицами.
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
        }
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
        if (!_isOneTime) ...[
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
          SizedBox(
            height: 40,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final weekday = index + 1; // 1 — пн, 7 — вс
                  final selected = _repeatWeekdays.contains(weekday);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _repeatWeekdays.remove(weekday);
                        } else {
                          _repeatWeekdays.add(weekday);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              selected ? theme.colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        weekdayLabels[index],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
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

enum CreationSource {
  presetHabit,
  presetEvent,
  custom,
}
