import 'package:flutter/material.dart';

/// Вкладка как категории в экране добавления привычки: фон #F3EFE9, акцентная
/// обводка и подчёркивание у выбранной.
class CategoryPill extends StatelessWidget {
  const CategoryPill({
    super.key,
    required this.text,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.expandWidth = false,
    this.height = 34,
  });

  final String text;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  /// Если true — растягивается по ширине родителя (например, [Expanded]).
  final bool expandWidth;

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const bg = Color(0xFFF3EFE9);
    const fg = Color(0xFF5A3E2B);
    final border = accent.withValues(alpha: 0.22);

    final inner = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: height,
          width: expandWidth ? double.infinity : null,
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
              textAlign: expandWidth ? TextAlign.center : TextAlign.start,
            ),
          ),
        ),
        if (selected)
          Positioned(
            left: 14,
            right: 14,
            // underline is intentionally outside the pill
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
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: inner,
      ),
    );
  }
}
