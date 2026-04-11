import 'package:flutter/material.dart';

import '../ui/app_icons.dart';
import '../ui/responsive.dart';
import 'skipped_indicator.dart';
import 'time_input_dialog.dart';

class HabitCounterCard extends StatelessWidget {
  const HabitCounterCard({
    super.key,
    required this.title,
    required this.unit,
    required this.current,
    required this.goal,
    this.isCompleted = false,
    this.isSkipped = false,
    this.onAdd,
    this.onSetValue,
    /// Тап по области прогресса/названия (не по счётчику и не по +) — открыть редактор.
    this.onOpenEdit,
    this.customColor,
    this.accent = const Color(0xFFFF7A00),
  });

  final String title;
  final String unit;
  final int current;
  final int goal;
  final bool isCompleted;
  final bool isSkipped;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onSetValue;
  final VoidCallback? onOpenEdit;
  /// Если задан и не равен 0x00000000 — тонирует фон карточки.
  final Color? customColor;
  final Color accent;

  Color _tint(Color base, Color tint) {
    final opaque = Color(tint.value | 0xFF000000);
    return Color.lerp(base, opaque, 0.18)!;
  }

  static Widget _habitCounterLeadingIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Transform.translate(
        offset: const Offset(0, 4),
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: HabitAppIcon(size: 134.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeGoal = goal <= 0 ? 1 : goal;
    final clampedCurrent = current.clamp(0, safeGoal);
    final progress = (clampedCurrent / safeGoal).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final cardBg = isSkipped
        ? const Color(0xFFE6DED7) // пропущено
        : (isCompleted ? const Color(0xFFEDE6DE) : const Color(0xFFF3EFE9));
    final effectiveBg = (customColor != null && customColor!.value != 0)
        ? _tint(cardBg, customColor!)
        : cardBg;
    final contentOpacity = (isCompleted || isSkipped) ? 0.78 : 1.0;

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: AppResponsive.gap(context, base: 4),
        horizontal: AppResponsive.sidePadding(context),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.gap(context, base: 16),
        vertical: AppResponsive.gap(context, base: 6),
      ),
      constraints: BoxConstraints(minHeight: AppResponsive.minCardHeight(context)),
      decoration: BoxDecoration(
        // В точности как подложки дней в календаре.
        color: effectiveBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Opacity(
        opacity: contentOpacity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Expanded(
            child: onOpenEdit == null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _habitCounterLeadingIcon(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _HabitCounterMiddle(
                          title: title,
                          unit: unit,
                          clampedCurrent: clampedCurrent,
                          safeGoal: safeGoal,
                          isSkipped: isSkipped,
                          accent: accent,
                          progress: progress,
                          percent: percent,
                          onSetValue: onSetValue,
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onOpenEdit,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _habitCounterLeadingIcon(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _HabitCounterMiddle(
                            title: title,
                            unit: unit,
                            clampedCurrent: clampedCurrent,
                            safeGoal: safeGoal,
                            isSkipped: isSkipped,
                            accent: accent,
                            progress: progress,
                            percent: percent,
                            onSetValue: onSetValue,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: Center(
              child: isSkipped
                  ? const SkippedIndicator()
                  : (isCompleted
                      ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                            border: Border.all(color: accent, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 22,
                          ),
                        )
                      : InkResponse(
                          onTap: onAdd,
                          radius: 22,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8D2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add, color: accent, size: 22),
                          ),
                        )),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _HabitCounterMiddle extends StatelessWidget {
  const _HabitCounterMiddle({
    required this.title,
    required this.unit,
    required this.clampedCurrent,
    required this.safeGoal,
    required this.isSkipped,
    required this.accent,
    required this.progress,
    required this.percent,
    required this.onSetValue,
  });

  final String title;
  final String unit;
  final int clampedCurrent;
  final int safeGoal;
  final bool isSkipped;
  final Color accent;
  final double progress;
  final int percent;
  final ValueChanged<int>? onSetValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5A3E2B),
          ),
        ),
        const SizedBox(height: 1),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: (onSetValue == null || isSkipped)
              ? null
              : () async {
                  final value = await showTimeInputDialog(
                    context,
                    initial: clampedCurrent,
                    title: title,
                    suffix: unit,
                  );
                  if (value == null) return;
                  onSetValue!(value);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$clampedCurrent / $safeGoal $unit',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A6A54),
                    ),
                  ),
                  if (isSkipped)
                    const TextSpan(
                      text: '  Пропущено',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC56B5E),
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 6,
                  color: const Color(0xFFE9D9CC),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.lerp(
                                Colors.white,
                                accent,
                                0.35,
                              )!,
                              accent,
                            ],
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5A3E2B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
