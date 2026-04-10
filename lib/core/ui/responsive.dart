import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Small responsive helpers for spacing and sizing.
///
/// Goal: keep the UI consistent across devices without hardcoding magic pixels
/// everywhere. Values are clamped to preserve the intended design.
class AppResponsive {
  const AppResponsive._();

  static double _width(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// Horizontal screen padding for cards / calendar.
  ///
  /// Scales with width, clamped so it doesn't get too small or too huge.
  static double sidePadding(BuildContext context) {
    final w = _width(context);
    final v = w * 0.075; // ~28 on 375-390 width, ~72 on tablets before clamping
    return v.clamp(16.0, 28.0);
  }

  /// Base spacing unit (defaults around 8 on typical phones).
  static double gap(BuildContext context, {double base = 8}) {
    final w = _width(context);
    final scale = (w / 390.0).clamp(0.90, 1.15);
    return (base * scale);
  }

  /// Minimum card height. Cards can grow (e.g. large textScale),
  /// but won't shrink below the intended baseline.
  static double minCardHeight(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    // Keep baseline 64 for default text scale; allow a bit more room when
    // user increases system font size.
    return math.max(64.0, 64.0 * (0.92 + 0.08 * textScale).clamp(1.0, 1.20));
  }
}

