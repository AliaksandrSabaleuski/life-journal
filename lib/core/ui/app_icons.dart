import 'package:flutter/material.dart';

class AppAssets {
  AppAssets._();

  static const String habit = 'assets/icons/habit.png';
}

class HabitAppIcon extends StatelessWidget {
  const HabitAppIcon({
    super.key,
    this.size = 32,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.habit,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

