import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/catalog/color_registry.dart';
import '../../../../core/models/habit.dart';
import '../../../../core/widgets/active_habit_card.dart';
import '../../../../core/widgets/bool_habit_card.dart';
import '../../../../core/widgets/habit_counter_card.dart';
import '../../../../core/widgets/underline_pill.dart';

Future<Habit?> showAddCustomHabitScreen(
  BuildContext context, {
  DateTime? initialDate,
}) {
  return Navigator.of(context).push<Habit?>(
    MaterialPageRoute(
      builder: (_) => AddCustomHabitScreen(initialDate: initialDate),
    ),
  );
}

enum _CustomKind { timeLimit, countLimit }

class AddCustomHabitScreen extends StatefulWidget {
  const AddCustomHabitScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<AddCustomHabitScreen> createState() => _AddCustomHabitScreenState();
}

class _AddCustomHabitScreenState extends State<AddCustomHabitScreen> {
  final _nameController = TextEditingController();
  final _goalController = TextEditingController(text: '30');
  final _unitController = TextEditingController(text: 'раз');

  _CustomKind _kind = _CustomKind.timeLimit;

  // 0x00000000 = "дефолтный, без кастомного цвета"
  Color _selectedColor = const Color(0x00000000);

  bool _daily = true;
  final Set<int> _weekdays = {1, 2, 3, 4, 5, 6, 7};

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _unitController.dispose();
    super.dispose();
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

  int _parseGoalOrDefault() {
    final v = int.tryParse(_goalController.text.trim());
    if (v == null) return _kind == _CustomKind.timeLimit ? 30 : 1;
    return v.clamp(1, 9999);
  }

  Habit _buildHabit() {
    final now = DateTime.now();
    final day = widget.initialDate ??
        DateTime(now.year, now.month, now.day, 12, 0);
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 365 - 1));

    final kind = _kind;
    final goalValue = _parseGoalOrDefault();
    final measurement = kind == _CustomKind.timeLimit
        ? HabitMeasurement.timed
        : HabitMeasurement.counted;
    final unit = kind == _CustomKind.timeLimit ? 'минут' : _unitController.text.trim();

    return Habit(
      id: 'custom_${now.millisecondsSinceEpoch}',
      name: _nameController.text.trim().isEmpty ? 'Новая привычка' : _nameController.text.trim(),
      direction: HabitDirection.good,
      measurement: measurement,
      goal: HabitGoal.target(goalValue.toDouble()),
      color: _selectedColor.value == 0 ? const Color(0x00000000) : _selectedColor,
      icon: null,
      unit: unit.isEmpty ? (measurement == HabitMeasurement.timed ? 'минут' : 'раз') : unit,
      repeatDays: _daily ? const [] : (_weekdays.toList()..sort()),
      reminder: null,
      startDate: start,
      endDate: end,
      isEvent: false,
      templateId: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    final habit = _buildHabit();
    final goalValue = (habit.goal.value ?? 1).round();

    final preview = habit.measurement == HabitMeasurement.timed
        ? ActiveHabitCard(
            title: habit.name,
            unit: habit.unit ?? 'минут',
            goalMinutes: goalValue,
            accent: accent,
            initialSeconds: 0,
            onSave: null,
            customColor: habit.color.value == 0 ? null : habit.color,
            readOnly: true,
          )
        : HabitCounterCard(
            title: habit.name,
            unit: habit.unit ?? 'раз',
            current: 0,
            goal: goalValue,
            accent: accent,
            customColor: habit.color.value == 0 ? null : habit.color,
            onAdd: null,
            onSetValue: null,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Создать свою')),
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
                  onPressed: () => Navigator.of(context).pop(_buildHabit()),
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
            _AdaptiveModeBar(
              selected: _kind,
              accent: accent,
              onSelected: (k) {
                setState(() {
                  _kind = k;
                  if (k == _CustomKind.timeLimit) {
                    if (_goalController.text.trim().isEmpty) _goalController.text = '30';
                  } else {
                    if (_goalController.text.trim().isEmpty) _goalController.text = '1';
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название привычки'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final label =
                    _kind == _CustomKind.timeLimit ? 'Минут в день' : 'Сколько в день';
                final tight = constraints.maxWidth < 360;

                final goalField = SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _goalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(),
                    onChanged: (_) => setState(() {}),
                  ),
                );

                final unitWidget = _kind == _CustomKind.countLimit
                    ? SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _unitController,
                          decoration: const InputDecoration(labelText: 'Ед.'),
                          onChanged: (_) => setState(() {}),
                        ),
                      )
                    : const Text('мин');

                if (!tight) {
                  return Row(
                    children: [
                      Text(label),
                      const SizedBox(width: 12),
                      goalField,
                      const SizedBox(width: 10),
                      unitWidget,
                    ],
                  );
                }

                // Узкий экран: переносим единицы на следующую строку, чтобы не было overflow.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        goalField,
                        const SizedBox(width: 10),
                        Flexible(child: unitWidget),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Цвет карточки'),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 22,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
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
                                      ? accent.withValues(alpha: 0.85)
                                      : Colors.black26,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5A3E2B)
                                        .withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...ColorRegistry.allColors.take(8).map((c) {
                            final selected = c.value == _selectedColor.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => setState(() => _selectedColor = c),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c,
                                    border: Border.all(
                                      color: selected
                                          ? Colors.black54
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Повторимость'),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
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
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            preview,
          ],
        ),
      ),
    );
  }
}

class _AdaptiveModeBar extends StatelessWidget {
  const _AdaptiveModeBar({
    required this.selected,
    required this.accent,
    required this.onSelected,
  });

  final _CustomKind selected;
  final Color accent;
  final ValueChanged<_CustomKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        const gap = 10.0;
        final left = _ModePill(
          text: 'Лимит времени',
          selected: selected == _CustomKind.timeLimit,
          accent: accent,
          onTap: () => onSelected(_CustomKind.timeLimit),
        );
        final right = _ModePill(
          text: 'Лимит количества',
          selected: selected == _CustomKind.countLimit,
          accent: accent,
          onTap: () => onSelected(_CustomKind.countLimit),
        );

        // Если влазит — растягиваем на всю ширину. Если нет — горизонтальный скролл.
        const approxPill = 140.0;
        final fits = constraints.maxWidth >= (approxPill * 2 + gap);

        if (fits) {
          return SizedBox(
            height: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                left,
                right,
              ],
            ),
          );
        }

        return SizedBox(
          height: 34,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                left,
                const SizedBox(width: gap),
                right,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
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
    const bg = Color(0xFFF3EFE9);
    const fg = Color(0xFF5A3E2B);
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
                border: Border.all(
                  color: accent.withValues(alpha: 0.22),
                  width: 1,
                ),
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

