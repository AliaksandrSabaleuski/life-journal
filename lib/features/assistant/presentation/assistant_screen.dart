import 'package:flutter/material.dart';

import '../../../../app/strings_ru.dart';
import '../../shell/shell_content_insets.dart';

/// Экран помощника.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: ShellContentInsets.top(context),
        bottom: ShellContentInsets.bottom(context),
      ),
      child: Center(
        child: Text(
          StringsRu.tabAssistant,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
