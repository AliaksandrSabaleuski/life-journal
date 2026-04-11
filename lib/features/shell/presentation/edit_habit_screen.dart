import 'package:flutter/material.dart';

import '../../../../core/catalog/color_registry.dart';
import '../../../../core/models/habit.dart';
import '../../../../core/widgets/active_habit_card.dart';
import '../../../../core/widgets/bool_habit_card.dart';
import '../../../../core/widgets/habit_counter_card.dart';
import '../../../../core/widgets/underline_pill.dart';
import '../../../../l10n/app_localizations.dart';

Future<Habit?> showEditHabitDialog(
  BuildContext context,
  Habit habit, {
  DateTime? selectedDate,
}) {
  return Navigator.of(context).push<Habit?>(
    MaterialPageRoute(
      builder: (_) => EditHabitScreen(
        habit: habit,
        selectedDate: selectedDate,
      ),
    ),
  );
}

class EditHabitScreen extends StatefulWidget {
  const EditHabitScreen({
    super.key,
    required this.habit,
    this.selectedDate,
  });

  final Habit habit;
  final DateTime? selectedDate;

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  late TextEditingController _unitController;

  /// 0x00000000 — дефолтный цвет карточки (как при добавлении).
  late Color _selectedColor;

  late bool _isOneTime;
  late Set<int> _repeatWeekdays;
  bool _daily = true;
  DateTime? _startDate;
  DateTime? _endDate;

  static const _coffee = Color(0xFF5A3E2B);

  static DateTime _cal(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameCal(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isEveryDay(Set<int> days) {
    if (days.length != 7) return false;
    for (var d = 1; d <= 7; d++) {
      if (!days.contains(d)) return false;
    }
    return true;
  }

  /// Пустой [Habit.repeatDays] = каждый день; для сравнения приводим к одному виду.
  static List<int> _normalizedRepeatWeekdays(Habit h) {
    final r = h.repeatDays;
    if (r.isEmpty) return const [1, 2, 3, 4, 5, 6, 7];
    final out = List<int>.from(r)..sort();
    return out;
  }

  static bool _sameSortedIntList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h.name);
    _selectedColor = h.color.value == 0 ? const Color(0x00000000) : h.color;
    final v = h.goal.value;
    _goalController = TextEditingController(text: v != null ? v.toInt().toString() : '');
    _unitController = TextEditingController(
      text: h.unit ?? (h.measurement == HabitMeasurement.timed ? 'мин' : 'раз'),
    );

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
      _daily = false;
    } else {
      _repeatWeekdays = h.repeatDays.isNotEmpty
          ? Set<int>.from(h.repeatDays)
          : {1, 2, 3, 4, 5, 6, 7};
      _endDate = end;
      _daily = h.repeatDays.isEmpty || _isEveryDay(_repeatWeekdays);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickTimedUnit(AppLocalizations l) async {
    final theme = Theme.of(context);
    const minLabel = 'мин';
    const hLabel = 'ч';
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l.unitMinutesLong),
              trailing: Text(minLabel, style: theme.textTheme.titleSmall),
              onTap: () => Navigator.pop(ctx, minLabel),
            ),
            ListTile(
              title: Text(l.unitHoursLong),
              trailing: Text(hLabel, style: theme.textTheme.titleSmall),
              onTap: () => Navigator.pop(ctx, hLabel),
            ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _unitController.text = picked);
    }
  }

  Future<bool> _pickWeekdays() async {
    final l = AppLocalizations.of(context)!;
    final selected = Set<int>.from(_repeatWeekdays);
    final res = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) {
        const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
        return AlertDialog(
          title: Text(l.pickDaysTitle),
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
              child: Text(l.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: Text(l.okButton),
            ),
          ],
        );
      },
    );
    if (res == null) return false;
    setState(() {
      _daily = false;
      _isOneTime = false;
      _repeatWeekdays
        ..clear()
        ..addAll(res.isEmpty ? const {1, 2, 3, 4, 5, 6, 7} : res);
    });
    return true;
  }

  (HabitPriorRules?, DateTime?) _versioningForSave(Habit opened, Habit preview) {
    final now = DateTime.now();
    final todayCal = _cal(now);
    final editDayCal = widget.selectedDate != null
        ? _cal(widget.selectedDate!)
        : todayCal;

    HabitPriorRules? priorOut = opened.priorRules;
    DateTime? effectiveOut = opened.rulesEffectiveFrom;

    // Смена дней недели: новое расписание только со дня **после** дня в календаре;
    // день открытия редактора и всё прошлое — старый набор дней (prior).
    if (!_isOneTime) {
      final before = _normalizedRepeatWeekdays(opened.forDate(editDayCal));
      final after = _normalizedRepeatWeekdays(preview);
      if (!_sameSortedIntList(before, after)) {
        priorOut = HabitPriorRules.fromHabit(opened.forDate(editDayCal));
        effectiveOut = editDayCal.add(const Duration(days: 1));
        return (priorOut, effectiveOut);
      }
    }

    if (_sameCal(editDayCal, todayCal)) {
      if (opened.rulesEffectiveFrom == null) {
        priorOut = HabitPriorRules.fromHabit(opened);
        effectiveOut = todayCal;
      } else {
        final from = _cal(opened.rulesEffectiveFrom!);
        if (!_sameCal(from, todayCal)) {
          priorOut = HabitPriorRules.fromHabit(opened);
          effectiveOut = todayCal;
        } else {
          priorOut = opened.priorRules;
          effectiveOut = opened.rulesEffectiveFrom;
        }
      }
    }

    return (priorOut, effectiveOut);
  }

  Habit _habitFromForm(Habit opened) {
    final isBinary = opened.measurement == HabitMeasurement.binary;
    HabitGoal goal;
    String? unit;

    if (isBinary) {
      goal = const HabitGoal.noGoal();
      unit = null;
    } else if (opened.measurement == HabitMeasurement.counted) {
      final v = double.tryParse(_goalController.text.replaceAll(',', '.')) ?? 1.0;
      unit = _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'раз';
      goal = HabitGoal.target(v);
    } else {
      final v = double.tryParse(_goalController.text.replaceAll(',', '.')) ?? 15.0;
      unit = _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'мин';
      goal = HabitGoal.target(v);
    }

    final now = DateTime.now();
    final todayCal = DateTime(now.year, now.month, now.day);
    final baseDate = opened.startDate != null
        ? DateTime(opened.startDate!.year, opened.startDate!.month, opened.startDate!.day)
        : todayCal;
    // День, в котором открыли редактор (главный экран всегда передаёт selectedDate).
    final invocationCal = widget.selectedDate != null
        ? DateTime(
            widget.selectedDate!.year,
            widget.selectedDate!.month,
            widget.selectedDate!.day,
          )
        : baseDate;

    DateTime? startDate;
    DateTime? endDate = _endDate;
    List<int> repeatDays;

    if (_isOneTime) {
      // Одноразовое: один календарный день = день вызова окна (не «старый» start из данных).
      startDate = invocationCal;
      endDate = invocationCal;
      repeatDays = const [];
    } else {
      startDate = _startDate ?? baseDate;
      endDate ??= baseDate.add(const Duration(days: 30));
      if (_daily) {
        repeatDays = const [];
      } else if (_repeatWeekdays.isEmpty) {
        repeatDays = const [1, 2, 3, 4, 5, 6, 7];
      } else {
        repeatDays = _repeatWeekdays.toList()..sort();
      }
    }

    final colorOut =
        _selectedColor.value == 0 ? const Color(0x00000000) : _selectedColor;

    return Habit(
      id: opened.id,
      name: _nameController.text.trim(),
      direction: opened.direction,
      measurement: opened.measurement,
      goal: goal,
      color: colorOut,
      icon: opened.icon,
      unit: unit,
      repeatDays: repeatDays,
      isActive: opened.isActive,
      reminder: opened.reminder,
      startTime: opened.startTime,
      startDate: startDate,
      endDate: endDate,
      isEvent: opened.isEvent,
      templateId: opened.templateId,
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final opened = widget.habit;
    final preview = _habitFromForm(opened);
    final (priorOut, effectiveOut) = _versioningForSave(opened, preview);

    Navigator.of(context).pop(
      preview.copyWith(
        rulesEffectiveFrom: effectiveOut,
        priorRules: priorOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final h = widget.habit;
    final isBinary = h.measurement == HabitMeasurement.binary;
    final isTimed = h.measurement == HabitMeasurement.timed;
    final isCounted = h.measurement == HabitMeasurement.counted;

    final typeKindLabel = isBinary
        ? l.editHabitExecutionKind
        : (isTimed ? l.goalTypeTime : l.goalTypeQuantity);

    final now = DateTime.now();
    final invocationDay = widget.selectedDate != null
        ? DateTime(
            widget.selectedDate!.year,
            widget.selectedDate!.month,
            widget.selectedDate!.day,
          )
        : DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.editHabitTitle),
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
                  child: Text(l.cancelButton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: Text(l.saveButton),
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
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l.editHabitNameLabel,
                hintText: l.editHabitNameHint,
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.titleSmall,
                      children: [
                        TextSpan(
                          text: '${l.editHabitTypePrefix} ',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextSpan(
                          text: typeKindLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isBinary) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(
                            l.editHabitGoalRow,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l.editHabitExecutionKind,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.editHabitBinaryDetail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ] else if (isTimed) ...[
                    TextField(
                      controller: _goalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.editHabitGoalRow.replaceAll(':', ''),
                        hintText: l.editHabitTimeGoalHint,
                        suffixText: _unitController.text,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.editHabitUnitRow,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _unitController.text.isEmpty ? 'мин' : _unitController.text,
                            style: theme.textTheme.bodyLarge,
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      onTap: () => _pickTimedUnit(l),
                    ),
                  ] else if (isCounted) ...[
                    TextField(
                      controller: _goalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.editHabitGoalRow.replaceAll(':', ''),
                        hintText: l.editHabitCountGoalHint,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: l.editHabitUnitRow.replaceAll(':', ''),
                        hintText: 'раз, км, стр.',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(l.cardColorLabel),
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
                                color: _coffee.withValues(alpha: 0.55),
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
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.editHabitOneTimeTitle),
              subtitle: Text(
                l.editHabitOneTimeSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: _isOneTime,
              onChanged: (v) {
                setState(() {
                  _isOneTime = v;
                  if (v) {
                    _daily = false;
                    _repeatWeekdays.clear();
                  } else {
                    _repeatWeekdays
                      ..clear()
                      ..addAll(const [1, 2, 3, 4, 5, 6, 7]);
                    _daily = true;
                  }
                });
              },
            ),
            if (!_isOneTime) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(l.repeatabilityLabel),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        UnderlinePill(
                          text: l.repeatDaily,
                          selected: _daily,
                          accent: accent,
                          onTap: () => setState(() {
                            _daily = true;
                            _repeatWeekdays
                              ..clear()
                              ..addAll(const [1, 2, 3, 4, 5, 6, 7]);
                          }),
                        ),
                        UnderlinePill(
                          text: l.repeatPickDays,
                          selected: !_daily,
                          accent: accent,
                          onTap: () async {
                            final applied = await _pickWeekdays();
                            if (!mounted || !applied) return;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SchedulePeriodSection(
                l: l,
                invocationDay: invocationDay,
                endDate: _endDate,
                onPickEnd: () async {
                  final rawStart =
                      _startDate ?? widget.habit.startDate ?? invocationDay;
                  final floor =
                      rawStart.isBefore(invocationDay) ? invocationDay : rawStart;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? floor.add(const Duration(days: 30)),
                    firstDate: floor,
                    lastDate: floor.add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null && mounted) {
                    setState(() {
                      _endDate = DateTime(picked.year, picked.month, picked.day);
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
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

                final startDate = habit.startDate;
                if (startDate != null && newEnd.isBefore(startDate)) {
                  if (!mounted) return;
                  Navigator.of(context).pop(habit.copyWith(isActive: false));
                  return;
                }

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l.editDeleteHabitConfirmTitle),
                    content: Text(l.editDeleteHabitConfirmBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(l.cancelButton),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text(l.deleteButton),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  Navigator.of(context).pop(habit.copyWith(endDate: newEnd));
                }
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text(l.deleteButton, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l.previewTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _coffee,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _EditHabitPreview(
              habit: _habitFromForm(h),
              accent: accent,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SchedulePeriodSection extends StatelessWidget {
  const _SchedulePeriodSection({
    required this.l,
    required this.invocationDay,
    required this.endDate,
    required this.onPickEnd,
  });

  final AppLocalizations l;
  /// День открытия редактора — нижняя граница для выбора конца периода.
  final DateTime invocationDay;
  final DateTime? endDate;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final end = endDate ??
        invocationDay.add(const Duration(days: 30));
    final endStr =
        '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(l.habitPeriodEnd),
      subtitle: Text(
        endStr,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onPickEnd,
    );
  }
}

class _EditHabitPreview extends StatelessWidget {
  const _EditHabitPreview({
    required this.habit,
    required this.accent,
  });

  final Habit habit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final custom = habit.color.value == 0 ? null : habit.color;

    switch (habit.measurement) {
      case HabitMeasurement.counted:
        final goal = (habit.goal.value ?? 1).round();
        return HabitCounterCard(
          title: habit.name,
          unit: habit.unit ?? 'раз',
          current: 0,
          goal: goal <= 0 ? 1 : goal,
          accent: accent,
          customColor: custom,
          onAdd: null,
          onSetValue: null,
        );
      case HabitMeasurement.timed:
        final goal = (habit.goal.value ?? 15).round();
        return ActiveHabitCard(
          title: habit.name,
          unit: habit.unit ?? 'мин',
          goalMinutes: goal <= 0 ? 1 : goal,
          accent: accent,
          initialSeconds: 0,
          onSave: null,
          customColor: custom,
          readOnly: true,
        );
      case HabitMeasurement.binary:
        return BoolHabitCard(
          title: habit.name,
          state: BoolHabitState.notDone,
          customColor: custom,
          onToggle: null,
        );
    }
  }
}
