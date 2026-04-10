import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/catalog/color_registry.dart';
import '../../../../core/catalog/habit_template.dart';
import '../../../../core/catalog/habits_catalog.dart';
import '../../../../core/models/habit.dart';
import '../../../../core/widgets/active_habit_card.dart';
import '../../../../core/widgets/bool_habit_card.dart';
import '../../../../core/widgets/habit_counter_card.dart';
import '../../../../core/widgets/underline_pill.dart';
import 'add_habit_wizard.dart';
import 'add_custom_habit_screen.dart';

Future<Habit?> showAddHabitScreen(
  BuildContext context, {
  required List<Habit> existingHabits,
  DateTime? initialDate,
}) {
  return Navigator.of(context).push<Habit?>(
    MaterialPageRoute(
      builder: (_) => AddHabitScreen(
        existingHabits: existingHabits,
        initialDate: initialDate,
      ),
    ),
  );
}

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({
    super.key,
    required this.existingHabits,
    this.initialDate,
  });

  final List<Habit> existingHabits;
  final DateTime? initialDate;

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  late final TextEditingController _nameController;

  HabitsCatalog? _catalog;
  String? _error;
  bool _loading = true;

  String _category = 'Здоровье';
  String? _selectedTemplateId;

  // 0x00000000 = "дефолтный, без кастомного цвета"
  Color _selectedColor = const Color(0x00000000);
  bool _daily = true;
  final Set<int> _weekdays = {1, 2, 3, 4, 5, 6, 7};


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadCatalog();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await HabitsCatalog.loadFromAsset();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loading = false;
      });
      _ensureValidSelection();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static const _categoryOrder = [
    'Здоровье',
    'Жизнь',
    'Развлечение',
    'Спорт',
    'Привычки',
  ];

  bool _isEveryDay(List<int> days) {
    if (days.length != 7) return false;
    final s = days.toSet();
    for (var d = 1; d <= 7; d++) {
      if (!s.contains(d)) return false;
    }
    return true;
  }

  List<HabitTemplate> _templatesForCategory(String category) {
    final catalog = _catalog;
    if (catalog == null) return const [];
    final usedTemplateIds = widget.existingHabits
        .where((h) => h.templateId != null)
        .map((h) => h.templateId!)
        .toSet();
    final list = catalog.items
        .where((t) => (t.category ?? 'Привычки') == category)
        .where((t) => !usedTemplateIds.contains(t.templateId))
        .toList();

    // stable ordering: order -> original index
    final originalIndexById = <String, int>{
      for (final e in catalog.items.asMap().entries) e.value.templateId: e.key,
    };
    list.sort((a, b) {
      final ao = a.order ?? 1 << 30;
      final bo = b.order ?? 1 << 30;
      if (ao != bo) return ao - bo;
      return (originalIndexById[a.templateId] ?? 0) -
          (originalIndexById[b.templateId] ?? 0);
    });
    return list;
  }

  HabitTemplate? _selectedTemplate() {
    final templates = _templatesForCategory(_category);
    final id = _selectedTemplateId;
    if (id == null) return templates.isEmpty ? null : templates.first;
    return templates.where((t) => t.templateId == id).firstOrNull ??
        (templates.isEmpty ? null : templates.first);
  }

  void _ensureValidSelection() {
    if (!mounted) return;
    if (!_categoryOrder.contains(_category)) _category = _categoryOrder.first;
    final templates = _templatesForCategory(_category);
    if (templates.isEmpty) {
      setState(() => _selectedTemplateId = null);
      return;
    }
    final currentId = _selectedTemplateId;
    final id =
        (currentId != null && templates.any((t) => t.templateId == currentId))
            ? currentId
            : templates.first.templateId;
    final selected = templates.firstWhere((t) => t.templateId == id);
    setState(() {
      _selectedTemplateId = id;
      _nameController.text = selected.name;
      _selectedColor = const Color(0x00000000);
      _daily = selected.repeatDays.isEmpty || _isEveryDay(selected.repeatDays);
      _weekdays
        ..clear()
        ..addAll(selected.repeatDays.isEmpty
            ? const [1, 2, 3, 4, 5, 6, 7]
            : selected.repeatDays);
    });
  }

  Future<bool> _pickWeekdays() async {
    final selected = Set<int>.from(_weekdays);
    final res = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) {
        const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
        return AlertDialog(
          title: const Text('Выбрать дни'),
          content: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final on = selected.contains(day);
                  return FilterChip(
                    label: Text(names[i]),
                    selected: on,
                    onSelected: (v) {
                      setStateDialog(() {
                        if (v) {
                          selected.add(day);
                        } else {
                          selected.remove(day);
                        }
                      });
                    },
                  );
                }),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (res == null) return false;
    setState(() {
      _daily = false;
      _weekdays
        ..clear()
        ..addAll(res.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : res);
    });
    return true;
  }

  Future<void> _createFromPreset() async {
    final t = _selectedTemplate();
    if (t == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final base = DateTime.now();
    final day = widget.initialDate ??
        DateTime(base.year, base.month, base.day, 12, 0);
    final start = DateTime(day.year, day.month, day.day);
    final end = t.durationDays == null
        ? null
        : start.add(Duration(days: t.durationDays! - 1));

    final habit = t.createInstance(
      instanceId: '${t.templateId}_${DateTime.now().millisecondsSinceEpoch}',
      color: _selectedColor.value == 0 ? const Color(0x00000000) : _selectedColor,
      icon: null,
      startDate: start,
      endDate: end,
      templateId: t.templateId,
    ).copyWith(
      name: name,
      repeatDays: _daily ? const [] : (_weekdays.toList()..sort()),
      reminder: null,
    );

    if (!mounted) return;
    Navigator.of(context).pop(habit);
  }

  Future<void> _openCustomFlow() async {
    final habit = await showAddCustomHabitScreen(
      context,
      initialDate: widget.initialDate,
    );
    if (!mounted) return;
    if (habit != null) Navigator.of(context).pop(habit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Добавить привычку')),
        body: Center(
          child: FilledButton.tonal(
            onPressed: _loadCatalog,
            child: const Text('Повторить'),
          ),
        ),
      );
    }

    final templates = _templatesForCategory(_category);
    final visibleTemplates = templates.take(4).toList(growable: false);
    final selectedId = _selectedTemplateId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить привычку'),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _createFromPreset,
                  child: const Text('Создать привычку'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          children: [
              _AdaptiveCategoryBar(
                categories: _categoryOrder,
                selected: _category,
                onSelected: (c) {
                  setState(() {
                    _category = c;
                    _selectedTemplateId = null;
                  });
                  _ensureValidSelection();
                },
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(10),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleTemplates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final t = visibleTemplates[i];
                    final isSelected = (selectedId ??
                            (visibleTemplates.isEmpty
                                ? null
                                : visibleTemplates.first.templateId)) ==
                        t.templateId;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedTemplateId = t.templateId;
                            _nameController.text = t.name;
                            _selectedColor = const Color(0x00000000);
                            _daily = t.repeatDays.isEmpty || _isEveryDay(t.repeatDays);
                            _weekdays
                              ..clear()
                              ..addAll(t.repeatDays.isEmpty
                                  ? const [1, 2, 3, 4, 5, 6, 7]
                                  : t.repeatDays);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.10)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.55)
                                  : theme.colorScheme.outline
                                      .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  t.name,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  width: 260,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: _openCustomFlow,
                    icon: const Icon(Icons.add, size: 27),
                    label: const Text('Создать свою'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: const StadiumBorder(),
                      side: BorderSide(
                        color: accent.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Имя берём из пресета; редактирование здесь не даём.
              Row(
                children: [
                  const Text('Цвет карточки'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        InkWell(
                          onTap: () => setState(
                            () => _selectedColor = const Color(0x00000000),
                          ),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF3EFE9),
                              border: Border.all(
                                color: _selectedColor.value == 0
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.85)
                                    : Colors.black26,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 8,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5A3E2B).withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ...ColorRegistry.allColors.take(8).map((c) {
                          final selected = c.value == _selectedColor.value;
                          return InkWell(
                            onTap: () => setState(() => _selectedColor = c),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c,
                                border: Border.all(
                                  color: selected ? Colors.black54 : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Повторимость'),
                  const SizedBox(width: 12),
                  UnderlinePill(
                    text: 'Ежедневно',
                    selected: _daily,
                    accent: accent,
                    onTap: () => setState(() {
                      _daily = true;
                      _weekdays
                        ..clear()
                        ..addAll(const [1, 2, 3, 4, 5, 6, 7]);
                    }),
                  ),
                  const SizedBox(width: 8),
                  UnderlinePill(
                    text: 'Выбрать дни',
                    selected: !_daily,
                    accent: accent,
                    onTap: () async {
                      final applied = await _pickWeekdays();
                      if (!mounted) return;
                      if (!applied) return;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Предпросмотр',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5A3E2B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _PreviewCard(
                template: _selectedTemplate(),
                accent: accent,
                customColor: _selectedColor,
              ),
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.template,
    required this.accent,
    required this.customColor,
  });

  final HabitTemplate? template;
  final Color accent;
  final Color customColor;

  @override
  Widget build(BuildContext context) {
    final t = template;
    if (t == null) return const SizedBox.shrink();

    // Рендерим карточку "как в меню": без выполненности, без пропуска.
    switch (t.measurement) {
      case HabitMeasurement.counted:
        final goal = (t.goal.value ?? 1).round();
        return HabitCounterCard(
          title: t.name,
          unit: t.unit ?? 'раз',
          current: 0,
          goal: goal <= 0 ? 1 : goal,
          accent: accent,
          customColor: customColor.value == 0 ? null : customColor,
        );
      case HabitMeasurement.timed:
        final goal = (t.goal.value ?? 30).round();
        return ActiveHabitCard(
          title: t.name,
          unit: t.unit ?? 'мин',
          goalMinutes: goal <= 0 ? 1 : goal,
          accent: accent,
          initialSeconds: 0,
          onSave: null,
          customColor: customColor.value == 0 ? null : customColor,
        );
      case HabitMeasurement.binary:
        return BoolHabitCard(
          title: t.name,
          state: BoolHabitState.notDone,
          onToggle: null,
          customColor: customColor.value == 0 ? null : customColor,
        );
    }
  }
}

class _AdaptiveCategoryBar extends StatelessWidget {
  const _AdaptiveCategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  double _pillWidth(BuildContext context, String text) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    const horizontalPadding = 14.0;
    const borderPadding = 2.0;
    return painter.width + horizontalPadding * 2 + borderPadding * 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    const gap = 10.0;
    const height = 34.0;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final total = categories.fold<double>(
              0,
              (sum, c) => sum + _pillWidth(context, c),
            ) +
            gap * (categories.length - 1);

        final fits = total <= constraints.maxWidth;

        final pills = categories
            .map(
              (c) => _CategoryPill(
                text: c,
                selected: c == selected,
                accent: accent,
                onTap: () => onSelected(c),
              ),
            )
            .toList(growable: false);

        if (fits) {
          return SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: pills,
            ),
          );
        }

        return SizedBox(
          height: height,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              dragDevices: const {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var i = 0; i < pills.length; i++) ...[
                    if (i != 0) const SizedBox(width: gap),
                    pills[i],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.text,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = const Color(0xFFF3EFE9);
    final fg = const Color(0xFF5A3E2B);
    final border = accent.withValues(alpha: 0.22);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: border, width: 1),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : const [],
              ),
              child: Center(
                child: Text(
                  text,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ),
            if (selected)
              Positioned(
                left: 14,
                right: 14,
                bottom: -6,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


