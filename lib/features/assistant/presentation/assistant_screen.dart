import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Экран помощника. Пока заглушка.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Text(
        l.tabAssistant,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
