import 'package:flutter/material.dart';

class UnderlinePill extends StatelessWidget {
  const UnderlinePill({
    super.key,
    required this.text,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.height = 32,
  });

  final String text;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final double height;

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
              height: height,
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

