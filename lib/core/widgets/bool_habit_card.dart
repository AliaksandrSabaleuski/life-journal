import 'package:flutter/material.dart';

import '../ui/app_icons.dart';
import '../ui/responsive.dart';
import '../ui/card_typography.dart';
import 'skipped_indicator.dart';
import 'success_pulse.dart';

enum BoolHabitState { notDone, done, skipped }

class BoolHabitCard extends StatelessWidget {
  const BoolHabitCard({
    super.key,
    required this.title,
    required this.state,
    this.onToggle,
    this.customColor,
    /// Текст под заголовком; круг отметки скрыт (онбординг и т.п.).
    this.previewSubtitle,
  });

  final String title;
  final BoolHabitState state;
  final VoidCallback? onToggle;
  /// Если задан и не равен 0x00000000 — тонирует фон карточки.
  final Color? customColor;
  final String? previewSubtitle;

  Color _tint(Color base, Color tint) {
    final opaque = Color(tint.value | 0xFF000000);
    return Color.lerp(base, opaque, 0.18)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const notDoneColor = Color(0xFF8C7A6B);
    const doneColor = Color(0xFF3C8C4A);
    const skippedColor = Color(0xFFC56B5E);
    const accent = Color(0xFFFF7A00);

    final bool isPreview = previewSubtitle != null;
    final bool isDone = !isPreview && state == BoolHabitState.done;
    final bool isSkipped = !isPreview && state == BoolHabitState.skipped;

    // В точности как подложки дней в календаре (и чуть темнее для состояний).
    final Color cardBg = isPreview
        ? const Color(0xFFF3EFE9)
        : switch (state) {
            BoolHabitState.notDone => const Color(0xFFF3EFE9),
            BoolHabitState.done => const Color(0xFFEDE6DE),
            BoolHabitState.skipped => const Color(0xFFE6DED7),
          };
    final effectiveBg = (customColor != null && customColor!.value != 0)
        ? _tint(cardBg, customColor!)
        : cardBg;
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

    final previewMargin = EdgeInsets.symmetric(
      vertical: isPreview ? 3 : AppResponsive.gap(context, base: 4),
      horizontal: isPreview ? 0 : 14,
    );
    final previewPadding = EdgeInsets.symmetric(
      horizontal: isPreview ? 12 : AppResponsive.gap(context, base: 16),
      vertical: isPreview ? 6 : AppResponsive.gap(context, base: 8),
    );
    final previewMinHeight =
        isPreview ? 0.0 : AppResponsive.minCardHeight(context);

    final borderRadius = BorderRadius.circular(isPreview ? 14 : 16);

    return SuccessPulse(
      trigger: isDone,
      borderRadius: borderRadius,
      highlightColor: accent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: previewMargin,
        padding: previewPadding,
        constraints: BoxConstraints(minHeight: previewMinHeight),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: borderRadius,
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
            child: const HabitCardLeadingSlot(
              child: HabitAppIcon(size: 134.4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isPreview
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        previewSubtitle!,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  )
                : SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CardTypography.title(
                            context,
                            color: isDone
                                ? notDoneColor
                                : theme.textTheme.titleSmall?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          statusText,
                          style: CardTypography.status(
                            context,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
          ),
          if (!isPreview) ...[
            const SizedBox(width: 16),
            Center(
              child: _StatusIndicator(
                state: state,
                accent: accent,
                onToggle: onToggle,
              ),
            ),
          ],
          ],
        ),
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
