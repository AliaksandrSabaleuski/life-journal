import 'package:flutter/material.dart';

/// Контент [MainShell] рисуется под AppBar и bottom bar; эти отступы — «безопасная» зона для тапов и текста.
abstract final class ShellContentInsets {
  static double top(BuildContext context) {
    return MediaQuery.viewPaddingOf(context).top + kToolbarHeight;
  }

  /// Пилюля навигации + FAB + home indicator.
  static double bottom(BuildContext context) {
    return 118 + MediaQuery.viewPaddingOf(context).bottom;
  }
}
