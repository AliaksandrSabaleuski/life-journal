import 'package:flutter/material.dart';

import '../../../../core/models/habit.dart';
import '../../../../core/widgets/habit_card.dart';
import '../../../../l10n/app_localizations.dart';

/// Контент главной вкладки: список карточек привычек, блок «Новое», мотивационный текст.
class MainMenuContent extends StatelessWidget {
  const MainMenuContent({
    super.key,
    required this.habits,
    this.isLoading = false,
  });

  final List<Habit> habits;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: habits.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => HabitCard(habit: habits[index]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                l.newBlockTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l.motivationalText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
