import 'package:flutter/material.dart';

/// Unified typography for habit/event cards.
///
/// Goal: card titles stand out; secondary text stays consistent across
/// counter/timer/bool cards and adapts to the app `ThemeData.textTheme`.
abstract final class CardTypography {
  CardTypography._();

  static TextStyle title(BuildContext context, {Color? color}) {
    final base = Theme.of(context).textTheme.titleSmall ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w800);
    return base.copyWith(
      fontWeight: FontWeight.w800,
      color: color ?? base.color,
      height: 1.2,
    );
  }

  static TextStyle secondary(BuildContext context, {Color? color}) {
    final base = Theme.of(context).textTheme.labelSmall ??
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
    return base.copyWith(
      fontWeight: FontWeight.w600,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.2,
    );
  }

  static TextStyle percent(BuildContext context, {Color? color}) {
    final base = Theme.of(context).textTheme.labelSmall ??
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w700);
    return base.copyWith(
      fontWeight: FontWeight.w800,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      height: 1.1,
    );
  }

  static TextStyle status(BuildContext context, {Color? color}) {
    final base = Theme.of(context).textTheme.bodySmall ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
    return base.copyWith(
      fontWeight: FontWeight.w500,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.2,
    );
  }
}

