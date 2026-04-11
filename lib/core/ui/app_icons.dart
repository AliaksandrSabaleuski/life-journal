import 'package:flutter/material.dart';

class AppAssets {
  AppAssets._();

  static const String habit = 'assets/icons/habit.png';
  static const String onboardingWelcome = 'assets/icons/onboardingicon.png';
}

/// Слот иконки карточки привычки: 48×48, крупный ассет через [OverflowBox] (как в списке).
class HabitCardLeadingSlot extends StatelessWidget {
  const HabitCardLeadingSlot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Align(
        alignment: const Alignment(0, 0.25),
        child: Transform.translate(
          offset: const Offset(0, 4),
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }
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

