import 'package:flutter/material.dart';

import '../ui/app_icons.dart';
import '../ui/responsive.dart';
import 'skipped_indicator.dart';

enum BoolHabitState { notDone, done, skipped }

class BoolHabitCard extends StatelessWidget {
  const BoolHabitCard({
    super.key,
    required this.title,
    required this.state,
    this.onToggle,
  });

  final String title;
  final BoolHabitState state;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF5A3E2B);
    const notDoneColor = Color(0xFF8C7A6B);
    const doneColor = Color(0xFF3C8C4A);
    const skippedColor = Color(0xFFC56B5E);
    const accent = Color(0xFFFF7A00);

    final bool isDone = state == BoolHabitState.done;
    final bool isSkipped = state == BoolHabitState.skipped;
    final bool isNotDone = state == BoolHabitState.notDone;

    // В точности как подложки дней в календаре (и чуть темнее для состояний).
    final Color cardBg = switch (state) {
      BoolHabitState.notDone => const Color(0xFFF3EFE9),
      BoolHabitState.done => const Color(0xFFEDE6DE),
      BoolHabitState.skipped => const Color(0xFFE6DED7),
    };
    final double contentOpacity = (isDone || isSkipped) ? 0.78 : 1.0;

    final String statusText = switch (state) {
      BoolHabitState.notDone => 'Не выполнено',
      BoolHabitState.done => 'Выполнено',
      BoolHabitState.skipped => 'Пропущено',
    };

    final Color statusColor = switch (state) {
      BoolHabitState.notDone => notDoneColor,
      BoolHabitState.done => doneColor,
      BoolHabitState.skipped => skippedColor,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.symmetric(
        vertical: AppResponsive.gap(context, base: 4),
        horizontal: AppResponsive.sidePadding(context),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.gap(context, base: 16),
        vertical: AppResponsive.gap(context, base: 8),
      ),
      constraints: BoxConstraints(minHeight: AppResponsive.minCardHeight(context)),
      decoration: BoxDecoration(
        color: cardBg,
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
          Opacity(
            opacity: isDone ? 0.6 : 1.0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
              ),
              child: Align(
                // Визуальное центрирование ассета (у него "тяжёлый" верх),
                // поэтому сдвигаем чуть вниз.
                alignment: const Alignment(0, 0.25),
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
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ).copyWith(
                      color: isDone ? notDoneColor : titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 48,
            child: Center(
              child: _StatusIndicator(
                state: state,
                accent: accent,
                onToggle: onToggle,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.state,
    required this.accent,
    required this.onToggle,
  });

  final BoolHabitState state;
  final Color accent;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final isDone = state == BoolHabitState.done;
    final isSkipped = state == BoolHabitState.skipped;

    if (isSkipped) {
      return const SkippedIndicator();
    }

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? accent : Colors.transparent,
          border: Border.all(
            color: accent,
            width: 2,
          ),
        ),
        child: isDone
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}
