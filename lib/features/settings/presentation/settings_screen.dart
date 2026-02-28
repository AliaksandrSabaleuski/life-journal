import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Экран настроек. Пока заглушка, функционал — в следующем этапе.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
      ),
      body: Center(
        child: Text(
          l.settingsPlaceholder,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
