import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Экран статистики. Пока заглушка.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Text(
        l.tabStats,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
