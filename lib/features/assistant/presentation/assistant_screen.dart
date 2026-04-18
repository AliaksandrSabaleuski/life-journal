import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../shell/shell_content_insets.dart';

/// Экран помощника.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        top: ShellContentInsets.top(context),
        bottom: ShellContentInsets.bottom(context),
      ),
      child: Center(
        child: Text(
          l.tabAssistant,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
