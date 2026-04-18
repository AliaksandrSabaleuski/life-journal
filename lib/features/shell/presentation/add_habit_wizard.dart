import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/catalog/color_registry.dart';
import '../../../../core/catalog/habit_template.dart';
import '../../../../core/catalog/habits_catalog.dart';
import '../../../../core/catalog/icon_registry.dart';
import '../../../../core/models/habit.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../l10n/app_localizations.dart';

/// Акцент макета: тёмный magenta-red.
const _wizardAccent = Color(0xFFD81B60);

/// Минимальная яркость для чипов дней и пресетов (Pink 800).
const _chipAccent = Color(0xFFAD1457);

/// Поведение скролла без отображения скроллбара.
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

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
    this.initialCreationSource,
    this.existingHabits = const [],
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

  /// Выбор из меню +: 'preset' (преднастроенные действия) или 'custom' (кастомное).
  /// Если задан — пропускаем выбор привычка/событие, идём сразу к каталогу или к настройке.
  final String? initialCreationSource;

  /// Уже созданные привычки/события — шаблоны с таким templateId не показываем в списке.
  final List<Habit> existingHabits;

  @override
  State<AddHabitWizard> createState() => _AddHabitWizardState();
}

class _AddHabitWizardState extends State<AddHabitWizard> {
  late int _step;

  HabitsCatalog? _catalog;
  String? _catalogLoadError;
  String? _selectedTemplateId;
  bool _isCatalogLoading = false;
  bool _lockTypeSelection = false;

  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _unitController = TextEditingController();
  final _iconScrollController = ScrollController();
  final _colorScrollController = ScrollController();

  IconData _icon = Icons.star_rounded;
  Color _color = Colors.green;

  HabitDirection? _direction;
  HabitMeasurement? _measurement;

  double? _goalValue;
  String _goalUnit = '';

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

  bool get _isUnifiedAddFlow =>
      widget.initialCreationSource == null && !widget.isEventMode;

  @override
  void initState() {
    super.initState();
    _direction = widget.initialDirection;
    _measurement = widget.initialMeasurement;
    if (widget.initialCreationSource == 'preset') {
      _source = CreationSource.presetAction;
      _step = widget.startStep;
    } else if (widget.initialCreationSource == 'custom') {
      _source = CreationSource.custom;
      _step = 1;
    } else if (_isUnifiedAddFlow) {
      _source = CreationSource.presetAction;
      _step = widget.startStep;
    } else {
      _source =
          widget.isEventMode ? CreationSource.presetEvent : CreationSource.presetHabit;
      _step = widget.startStep;
    }
    _loadCatalog();
  }

  List<HabitTemplate> _templatesForCurrentSource() {
    final catalog = _catalog;
    if (catalog == null) return const [];
    final usedTemplateIds = widget.existingHabits
        .where((h) => h.templateId != null)
        .map((h) => h.templateId!)
        .toSet();
    List<HabitTemplate> list;
    switch (_source) {
      case CreationSource.presetHabit:
        list = catalog.habits.toList();
        break;
      case CreationSource.presetEvent:
        list = catalog.events.toList();
        break;
      case CreationSource.presetAction:
        list = catalog.items;
        break;
      case CreationSource.custom:
        return const [];
    }
    return list.where((t) => !usedTemplateIds.contains(t.templateId)).toList();
  }

  /// Шаблон по id из полного каталога (без фильтра «уже используется»).
  HabitTemplate? _resolveTemplateById(String? id) {
    if (id == null) return null;
    for (final t in _catalog?.items ?? const []) {
      if (t.templateId == id) return t;
    }
    return null;
  }

  /// Для шага 0: шаблоны для выбора (если все «использованы» — показываем весь каталог).
  List<HabitTemplate> _effectivePresetTemplates() {
    final presets = _templatesForCurrentSource();
    if (presets.isNotEmpty) return presets;
    return _catalog?.items ?? const [];
  }

  Widget _buildStepSource(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l,
  ) {
    final isEvent = widget.isEventMode;
    final presets = _source == CreationSource.presetAction
        ? _effectivePresetTemplates()
        : _templatesForCurrentSource();
    final fromAddMenu = widget.initialCreationSource != null;
    final unified = _isUnifiedAddFlow;

    final options = <Widget>[];

    // Унифицированный флоу: Преднастроенные | Кастомное
    if (unified) {
      options.add(
        RadioListTile<CreationSource>(
          value: CreationSource.presetAction,
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
          title: const Text('Преднастроенные действия'),
          subtitle: const Text('Выбрать из каталога'),
          contentPadding: EdgeInsets.zero,
        ),
      );
      options.add(
        RadioListTile<CreationSource>(
          value: CreationSource.custom,
          groupValue: _source,
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _source = v;
              _lockTypeSelection = false;
              // Сохраняем _selectedTemplateId — дропдаун преднастроенных показывает прежний выбор
              _ensurePresetSelectedForSource();
            });
          },
          title: const Text('Кастомное'),
          subtitle: const Text('Настроить действие с нуля'),
          contentPadding: EdgeInsets.zero,
        ),
      );
    } else if (!fromAddMenu && !isEvent) {
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
    }
    if (!fromAddMenu && isEvent && !unified) {
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

    if (!fromAddMenu && !unified) {
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
    }

    Widget buildDropdown({bool enabled = true}) {
      final catalogItems = _catalog?.items ?? const [];
      final hasCatalogItems = catalogItems.isNotEmpty;
      final resolved = _selectedTemplateId != null ? _resolveTemplateById(_selectedTemplateId) : null;
      final displayPresets = presets.isNotEmpty
          ? presets
          : (resolved != null ? [resolved] : hasCatalogItems ? catalogItems : <HabitTemplate>[]);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isCatalogLoading)
            const Center(child: CircularProgressIndicator())
          else if (_catalogLoadError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ошибка загрузки каталога',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => _loadCatalog(),
                  child: const Text('Повторить'),
                ),
              ],
            )
          else if (displayPresets.isEmpty)
            hasCatalogItems
                ? const SizedBox.shrink()
                : Text(
                    'Каталог пуст — добавьте шаблоны в конфиг.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
          else
            _TemplatePicker(
              presets: displayPresets,
              selectedTemplateId: _selectedTemplateId,
              onSelected: (id) => setState(() => _selectedTemplateId = id),
              labelText: 'Выберите действие',
              enabled: enabled,
            ),
          const SizedBox(height: 16),
        ],
      );
    }

    final dropdown = _source == CreationSource.custom && !unified
        ? const SizedBox.shrink()
        : buildDropdown(enabled: _source == CreationSource.presetAction);

    if (unified) {
      final isPreset = _source == CreationSource.presetAction;
      final catalogItems = _catalog?.items ?? const [];
      final hasCatalogItems = catalogItems.isNotEmpty;
      final resolved =
          _selectedTemplateId != null ? _resolveTemplateById(_selectedTemplateId) : null;
      final effectivePresets = presets.isNotEmpty
          ? presets
          : (resolved != null ? [resolved] : hasCatalogItems ? catalogItems : <HabitTemplate>[]);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DarkSourceBlock(
            isSelected: isPreset,
            onTap: () {
              setState(() {
                _source = CreationSource.presetAction;
                _lockTypeSelection = false;
                _ensurePresetSelectedForSource();
              });
            },
            icon: Icons.grid_view_rounded,
            title: 'Преднастроенные действия',
            subtitle: 'Выбрать из каталога',
            child: _DarkTemplatePicker(
              presets: effectivePresets,
              selectedTemplateId: _selectedTemplateId,
              onSelected: (id) => setState(() => _selectedTemplateId = id),
              enabled: isPreset,
              isLoading: _isCatalogLoading,
              loadError: _catalogLoadError,
              onRetry: _loadCatalog,
            ),
          ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pinkAccent, Colors.purpleAccent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DarkSourceBlock(
            isSelected: !isPreset,
            onTap: () {
              setState(() {
                _source = CreationSource.custom;
                _lockTypeSelection = false;
                _ensurePresetSelectedForSource();
              });
            },
            icon: Icons.add_circle_outline,
            title: 'Кастомное',
            subtitle: 'Настроить действие с нуля',
            child: null,
          ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          fromAddMenu && _source == CreationSource.presetAction
              ? 'Выберите действие'
              : 'Выберите из преднастроенных',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        dropdown,
        if (!fromAddMenu) ...[
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
      ],
    );
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

      // Преднастроенные действия (каталог привычек + событий): по типу шаблона
      if (_source == CreationSource.presetAction) {
        final templates = _effectivePresetTemplates();
        if (templates.isEmpty) return;
        final template = _resolveCurrentTemplate(templates);
        _applyPresetToState(template);
        setState(() {
          _lockTypeSelection = true;
          _step = template.isEvent ? 4 : 2;
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
    setState(() {
      _isCatalogLoading = true;
      _catalogLoadError = null;
    });
    try {
      final catalog = await HabitsCatalog.loadFromAsset();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _catalogLoadError = null;
        _ensurePresetSelectedForSource();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogLoadError = e.toString();
        _catalog = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isCatalogLoading = false);
      }
    }
  }

  Widget _buildOptionCard({
    required ThemeData theme,
    required CreationSource source,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _source == source;
    final cardColor = theme.colorScheme.surfaceContainerHighest;
    final borderSide = isSelected
        ? BorderSide(color: color.withValues(alpha: 0.7), width: 1.5)
        : BorderSide.none;
    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: borderSide,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          setState(() {
            _source = source;
            _lockTypeSelection = false;
            // При переключении на «Кастомное» сохраняем выбор в дропдауне преднастроенных
            if (source != CreationSource.custom) _selectedTemplateId = null;
            _ensurePresetSelectedForSource();
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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

  void _ensurePresetSelectedForSource() {
    // При выборе «Кастомное» сохраняем выбранный шаблон в дропдауне преднастроенных.
    if (_source == CreationSource.custom) return;
    final templates = _effectivePresetTemplates();
    if (templates.isEmpty) {
      _selectedTemplateId = null;
      return;
    }
    final hasCurrent =
        _selectedTemplateId != null && templates.any((t) => t.templateId == _selectedTemplateId);
    if (!hasCurrent) {
      _selectedTemplateId = templates.first.templateId;
    }
  }

  Future<void> _checkLimitAndPop(Habit habit) async {
    final canAdd = await SubscriptionService.canAdd(
      widget.existingHabits,
      isEvent: habit.isEvent,
    );
    if (!canAdd && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            SubscriptionService.getLimitReachedMessage(habit.isEvent),
          ),
        ),
      );
      return;
    }
    if (mounted) Navigator.of(context).pop(habit);
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
      templateId: template.templateId,
    );

    _checkLimitAndPop(habit);
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
        break;
      case HabitMeasurement.counted:
        final v = template.goal.value ?? 1;
        _goalValue = v;
        _goalController.text = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
        _unitController.text = template.unit ?? '';
        _goalUnit = template.unit ?? '';
        break;
      case HabitMeasurement.timed:
        final v = template.goal.value ?? 10;
        _goalValue = v;
        _goalController.text = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
        _unitController.text = template.unit ?? 'мин';
        _goalUnit = template.unit ?? 'мин';
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
      goal = HabitGoal.target(v);
    } else {
      // timed
      final v = (_goalValue ?? double.tryParse(_goalController.text.replaceAll(',', '.'))) ?? 15.0;
      unit = 'мин';
      goal = HabitGoal.target(v);
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

    final template = _source == CreationSource.presetAction
        ? _resolveCurrentTemplate(_templatesForCurrentSource())
        : null;
    final isEventFlag = widget.isEventMode ||
        _source == CreationSource.presetEvent ||
        (template?.isEvent ?? false);

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

    _checkLimitAndPop(habit);
  }

  bool get _canGoNext {
    switch (_step) {
      case 0:
        if (_source == CreationSource.custom) return true;
        if (_isCatalogLoading || _catalogLoadError != null) return false;
        return _source == CreationSource.presetAction
            ? _effectivePresetTemplates().isNotEmpty
            : _templatesForCurrentSource().isNotEmpty;
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

  static const _popupAccent = _wizardAccent;
  static const _popupAccentSecondary = Colors.purpleAccent;
  static const _popupBackground = Color(0xFF1a1a2e);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          surface: _popupBackground,
          onSurface: Colors.white,
          primary: _popupAccent,
          onPrimary: Colors.white,
          outline: Colors.white,
        ),
      ),
      child: Dialog(
        backgroundColor: _popupBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      _stepTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: Colors.white24,
              ),
              Flexible(
                child: ScrollConfiguration(
                  behavior: _NoScrollbarBehavior(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      _step == 0 ? 0 : 20,
                      12,
                      _step == 0 ? 0 : 20,
                      12,
                    ),
                    child: switch (_step) {
                    0 => _buildStepSource(context, theme, l),
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
              ),
            ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _back,
                          child: Text(
                            _step > 0 ? 'Назад' : l.cancelButton,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: _GradientButton(
                          onPressed: _canGoNext ? _next : null,
                          child: Text(_step == 4 ? l.saveButton : 'Далее'),
                        ),
                      ),
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

  String get _stepTitle {
    switch (_step) {
      case 0:
        if (widget.initialCreationSource == 'preset' || _isUnifiedAddFlow) {
          return 'Новое действие';
        }
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
    const labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Название привычки',
          style: labelStyle,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2d2d3d),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.pinkAccent),
            ),
          ),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: Colors.white24,
        ),
        const SizedBox(height: 20),
        Text('Иконка', style: labelStyle),
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
                          color: selected
                              ? _color.withValues(alpha: 0.2)
                              : const Color(0xFF2d2d3d),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.pinkAccent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: selected ? _color : Colors.white54,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: Colors.white24,
        ),
        const SizedBox(height: 20),
        Text('Цвет', style: labelStyle),
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
                            color: selected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
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
    // Только good + counted/timed (счётчик и таймер).
    final options = [
      _MeasurementOption(
        type: HabitMeasurement.timed,
        direction: HabitDirection.good,
        icon: Icons.timer_outlined,
        title: 'Таймер',
        subtitle: 'Делать N минут в день',
      ),
      _MeasurementOption(
        type: HabitMeasurement.counted,
        direction: HabitDirection.good,
        icon: Icons.format_list_numbered,
        title: 'Счётчик',
        subtitle: 'Сделать N раз',
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
        final label = 'Укажите целевое количество';
        final hint = 'Например: 5';
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
                  labelText: 'Цель',
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

  static const _frequencyLabelStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  Widget _buildDateRow({
    required String label,
    required String dateText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            const Spacer(),
            Text(dateText, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today, color: _wizardAccent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const borderSide = BorderSide(color: Color(0xFFFFE4EC), width: 1);
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Material(
          color: selected ? _chipAccent : Colors.transparent,
          shape: StadiumBorder(
            side: selected ? BorderSide.none : borderSide,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _chipAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isMuted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: selected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _chipAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : isMuted
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _chipAccent : Colors.transparent,
                    border: Border.all(color: _chipAccent),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : _chipAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
    );
  }

  Widget _buildStepFrequency(ThemeData theme) {
    final weekdayLabels = const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final now = DateTime.now();
    final baseDate = widget.initialDate != null
        ? DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day)
        : DateTime(now.year, now.month, now.day);
    final startDate = _startDate ?? baseDate;
    final endDate = _endDate ?? startDate.add(const Duration(days: 7));
    final startStr =
        '${startDate.day.toString().padLeft(2, '0')}.${startDate.month.toString().padLeft(2, '0')}.${startDate.year}';
    final endStr =
        '${endDate.day.toString().padLeft(2, '0')}.${endDate.month.toString().padLeft(2, '0')}.${endDate.year}';

    final isWeekdays = _repeatWeekdays.length == 5 &&
        _repeatWeekdays.containsAll({1, 2, 3, 4, 5});
    final isWeekends = _repeatWeekdays.length == 2 &&
        _repeatWeekdays.containsAll({6, 7});
    final isEveryDay = _repeatWeekdays.length == 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_isOneTime) ...[
          _buildDateRow(
            label: 'Дата начала',
            dateText: startStr,
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
                  if (_endDate != null && _endDate!.isBefore(_startDate!)) {
                    _endDate = _startDate!.add(const Duration(days: 30));
                  }
                });
              }
            },
          ),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          _buildDateRow(
            label: 'Дата окончания',
            dateText: endStr,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate,
                firstDate: startDate,
                lastDate: startDate.add(const Duration(days: 365 * 5)),
              );
              if (picked != null && mounted) {
                setState(() => _endDate = DateTime(picked.year, picked.month, picked.day));
              }
            },
          ),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Дни недели', style: _frequencyLabelStyle),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final selected = _repeatWeekdays.contains(weekday);
              return _buildFrequencyPill(
                label: weekdayLabels[index],
                selected: selected,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _repeatWeekdays.remove(weekday);
                    } else {
                      _repeatWeekdays.add(weekday);
                    }
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_wizardAccent, Colors.purpleAccent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Быстрый выбор', style: _frequencyLabelStyle),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetPill(
                label: 'Будни',
                selected: isWeekdays,
                onTap: () => setState(() {
                  _repeatWeekdays
                    ..clear()
                    ..addAll({1, 2, 3, 4, 5});
                }),
              ),
              _buildPresetPill(
                label: 'Выходные',
                selected: isWeekends,
                onTap: () => setState(() {
                  _repeatWeekdays
                    ..clear()
                    ..addAll({6, 7});
                }),
              ),
              _buildPresetPill(
                label: 'Каждый день',
                selected: isEveryDay,
                onTap: () => setState(() {
                  _repeatWeekdays
                    ..clear()
                    ..addAll({1, 2, 3, 4, 5, 6, 7});
                }),
              ),
              _buildPresetPill(
                label: 'Очистить',
                selected: false,
                isMuted: true,
                onTap: () => setState(() => _repeatWeekdays.clear()),
              ),
            ],
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

/// Категория шаблона для группировки в выборе.
String _templateCategory(HabitTemplate t) {
  return t.category ?? 'Привычки';
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_wizardAccent, Colors.purpleAccent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 48,
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkSourceBlock extends StatelessWidget {
  const _DarkSourceBlock({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.child,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    const blockBg = Color(0xFF252538);
    final content = Material(
      color: blockBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.pinkAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (child != null) ...[
                const SizedBox(height: 12),
                child!,
              ],
            ],
          ),
        ),
      ),
    );

    const borderPadding = EdgeInsets.all(2);
    return Container(
      padding: borderPadding,
      decoration: isSelected
          ? BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.pinkAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}

class _DarkTemplatePicker extends StatelessWidget {
  const _DarkTemplatePicker({
    required this.presets,
    required this.selectedTemplateId,
    required this.onSelected,
    required this.enabled,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
  });

  final List<HabitTemplate> presets;
  final String? selectedTemplateId;
  final void Function(String?)? onSelected;
  final bool enabled;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      );
    }
    if (loadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ошибка загрузки каталога',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ],
      );
    }
    if (presets.isEmpty) {
      return const Text(
        'Каталог пуст',
        style: TextStyle(color: Colors.white70),
      );
    }
    final selected = presets.any((t) => t.templateId == selectedTemplateId)
        ? presets.firstWhere((t) => t.templateId == selectedTemplateId)
        : presets.first;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purpleAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<HabitTemplate>(
            value: selected,
            focusColor: Colors.transparent,
            items: presets.map((t) {
            final ico = IconRegistry.byKey(t.iconKey) ?? Icons.star;
            return DropdownMenuItem<HabitTemplate>(
              value: t,
              child: Row(
                children: [
                  Icon(ico, color: Colors.pinkAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.name,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: enabled
              ? (t) {
                  if (t != null) onSelected?.call(t.templateId);
                }
              : null,
          isExpanded: true,
          dropdownColor: Colors.grey[850],
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        ),
      ),
    ),
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({
    required this.presets,
    required this.selectedTemplateId,
    required this.onSelected,
    required this.labelText,
    this.enabled = true,
  });

  final List<HabitTemplate> presets;
  final String? selectedTemplateId;
  final void Function(String?)? onSelected;
  final String labelText;
  final bool enabled;

  List<DropdownMenuItem<String>> _buildGroupedItems(ThemeData theme) {
    final grouped = <String, List<HabitTemplate>>{};
    final originalIndexById = <String, int>{
      for (final e in presets.asMap().entries) e.value.templateId: e.key,
    };
    for (final t in presets) {
      grouped.putIfAbsent(_templateCategory(t), () => []).add(t);
    }
    const categoryOrder = [
      'Здоровье',
      'Жизнь',
      'Развлечение',
      'Спорт',
      'Привычки',
    ];

    final items = <DropdownMenuItem<String>>[];
    final orderedCats = <String>[
      ...categoryOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !categoryOrder.contains(k)),
    ];
    for (final cat in orderedCats) {
      final list = (grouped[cat] ?? const <HabitTemplate>[]).toList()
        ..sort((a, b) {
          final ao = a.order ?? 1 << 30;
          final bo = b.order ?? 1 << 30;
          if (ao != bo) return ao - bo;
          return (originalIndexById[a.templateId] ?? 0) -
              (originalIndexById[b.templateId] ?? 0);
        });
      if (list.isEmpty) continue;
      items.add(
        DropdownMenuItem<String>(
          value: '__header_$cat',
          enabled: false,
          child: Text(
            cat,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      for (final t in list) {
        items.add(
          DropdownMenuItem<String>(
            value: t.templateId,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (IconRegistry.byKey(t.iconKey) != null) ...[
                  Icon(IconRegistry.byKey(t.iconKey), size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(t.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _buildGroupedItems(theme);
    final value = selectedTemplateId != null &&
            presets.any((t) => t.templateId == selectedTemplateId)
        ? selectedTemplateId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          labelText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: enabled
                  ? (v) {
                      if (v != null && !v.startsWith('__header_')) {
                        onSelected?.call(v);
                      }
                    }
                  : null,
              isExpanded: true,
              isDense: false,
            ),
          ),
        ),
      ],
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
  presetAction,
  custom,
}
