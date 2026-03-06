import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/catalog/habits_catalog.dart';
import '../../../core/catalog/color_registry.dart';
import '../../../core/catalog/icon_registry.dart';
import '../../../core/repositories/habits_repository.dart';
import '../../shell/presentation/main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0=welcome, 1=notifications
  bool _busy = false;
  static final HabitsRepository _habitsRepository = HabitsRepository.instance;

  Future<void> _createBaseHabits() async {
    final catalog = await HabitsCatalog.loadFromAsset();
    final today = DateTime.now();
    final baseTemplates = catalog.items.where((t) => t.isBase).toList();
    final baseId = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < baseTemplates.length; i++) {
      final t = baseTemplates[i];
      final color = ColorRegistry.byKey(t.colorKey);
      final icon = IconRegistry.byKey(t.iconKey);
      final duration = t.durationDays;
      final start = DateTime(today.year, today.month, today.day);
      final end = duration == null
          ? null
          : start.add(Duration(days: duration - 1));

      final habit = t.createInstance(
        instanceId: '${t.templateId}_${baseId}_$i',
        color: color,
        icon: icon,
        startDate: start,
        endDate: end,
        templateId: t.templateId,
      );
      await _habitsRepository.addHabit(habit);
    }
  }

  Future<void> _next() async {
    if (_busy) return;
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }

    setState(() => _busy = true);
    try {
      await NotificationService.instance.requestPermission();
      await _createBaseHabits();
      await OnboardingService.markCompleted();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const MainShell(openAddMenuOnStart: true),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    String title;
    String body;
    String buttonText;

    if (_step == 0) {
      title = 'Добро пожаловать';
      body = 'Это дневник привычек и событий.\n'
          'Отмечайте прогресс каждый день — приложение покажет статистику и поможет не сбиться с курса.';
      buttonText = 'Продолжить';
      content = _OnboardingCard(
        icon: Icons.waving_hand_outlined,
        title: title,
        body: body,
      );
    } else {
      title = 'Разрешение на уведомления';
      body = kIsWeb
          ? 'На вебе уведомления сейчас недоступны. Нажмите «Продолжить».'
          : 'Разрешите уведомления, чтобы получать напоминания о привычках.\n'
              'Вы сможете выключить их в настройках.';
      buttonText = _busy ? '...' : 'Продолжить';
      content = _OnboardingCard(
        icon: Icons.notifications_active_outlined,
        title: title,
        body: body,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: content,
                  ),
                ),
              ),
              FilledButton(
                onPressed: _busy ? null : _next,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    buttonText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

