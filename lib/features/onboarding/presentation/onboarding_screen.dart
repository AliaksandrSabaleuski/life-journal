import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/catalog/habits_catalog.dart';
import '../../../core/catalog/color_registry.dart';
import '../../../core/catalog/icon_registry.dart';
import '../../../core/repositories/habits_repository.dart';
import '../../../core/ui/app_icons.dart';
import '../../../core/widgets/bool_habit_card.dart';
import '../../shell/presentation/main_shell.dart';

const String _kFirstLaunchBackgroundAsset = 'assets/images/FirstLaunchBack.png';
const String _kMainBackgroundAsset = 'assets/images/Mainback.png';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // 0=splash (tree+title), 1=welcome (features), 2=notifications
  int _step = 0;
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
    if (_step == 0 || _step == 1) {
      setState(() => _step++);
      return;
    }

    setState(() => _busy = true);
    try {
      await NotificationService.instance.requestPermission();
      await _createBaseHabits();
      await OnboardingService.markCompleted();
      AnalyticsService.instance.logOnboardingCompleted();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const MainShell(),
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
    String buttonText;
    Widget? footer;

    if (_step == 0) {
      buttonText = 'Продолжить';
      content = const _SplashCard();
      footer = const _LegalFooter();
    } else if (_step == 1) {
      buttonText = 'Продолжить';
      content = const _WelcomeCard();
      footer = null;
    } else {
      buttonText = _busy ? '...' : 'Продолжить';
      content = const _NotificationsCard();
      footer = null;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              _step == 0
                  ? _kFirstLaunchBackgroundAsset
                  : _kMainBackgroundAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                _step == 0
                    ? 4
                    : _step == 1
                        ? 0
                        : 24,
                20,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _step == 0
                            ? SizedBox.expand(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: content,
                                ),
                              )
                            : content,
                      ),
                    ),
                  ),
                  if (footer != null && _step == 0) ...[
                    footer!,
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: (_step == 2 && _busy) ? null : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        buttonText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Первый экран: фон [FirstLaunchBack], заголовок, описание.
class _SplashCard extends StatelessWidget {
  const _SplashCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 150),
            Text(
              'Добро пожаловать в',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Приложение обо мне',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'дневник привычек',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Начните путешествие против своих слабостей и зависимостей. '
              'А данное приложение поможет вам отслеживать прогресс на протяжении всего пути '
              'и становиться лучшей версией себя.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Футер: ссылки на политику конфиденциальности и правила.
class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text.rich(
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        TextSpan(
          children: [
            const TextSpan(text: 'Используя приложение, вы соглашаетесь с '),
            TextSpan(
              text: 'Политикой конфиденциальности',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
                fontStyle: FontStyle.italic,
              ),
            ),
            const TextSpan(text: ' и '),
            TextSpan(
              text: 'Правилами пользования',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Второй шаг: прежние тексты, карточки как у [BoolHabitCard] (иконка habit.png).
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Добро пожаловать в ваш дневник!',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 46),
          BoolHabitCard(
            title: 'Сохраняйте моменты, важные для вас',
            state: BoolHabitState.notDone,
            previewSubtitle:
                'Наблюдайте за тем, как вы меняетесь и растете',
          ),
          BoolHabitCard(
            title: 'Храните свои мысли и идеи в тайне',
            state: BoolHabitState.notDone,
            previewSubtitle: 'Дневник только для ваших глаз',
          ),
          BoolHabitCard(
            title: 'Отслеживайте свои эмоции',
            state: BoolHabitState.notDone,
            previewSubtitle:
                'Отмечайте свои настроения и выявляйте закономерности',
          ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (kIsWeb) {
      return _NotificationsContent(
        theme: theme,
        title: 'Уведомления',
        features: const [
          _NotificationFeature(
            icon: Icons.notifications_outlined,
            text: 'На вебе уведомления сейчас недоступны.',
          ),
        ],
        infoText: 'Нажмите «Продолжить», чтобы перейти в приложение.',
      );
    }
    return _NotificationsContent(
      theme: theme,
      title: 'Разрешите приложению отправлять уведомления',
      features: const [
        _NotificationFeature(
          icon: Icons.favorite_border_rounded,
          text: 'Получайте напоминания о привычках',
        ),
        _NotificationFeature(
          icon: Icons.check_circle_outline_rounded,
          text: 'Не пропустите запланированные дела',
        ),
      ],
      infoText: 'Вы сможете поменять это позже в приложении «Настройки»',
    );
  }
}

class _NotificationFeature {
  const _NotificationFeature({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;
}

class _NotificationsContent extends StatelessWidget {
  const _NotificationsContent({
    required this.theme,
    required this.title,
    required this.features,
    required this.infoText,
  });

  final ThemeData theme;
  final String title;
  final List<_NotificationFeature> features;
  final String infoText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          for (final f in features) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  f.icon,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    f.text,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Transform.rotate(
                    angle: -15 * math.pi / 180,
                    child: Transform.scale(
                      scale: 2.5,
                      alignment: Alignment.center,
                      child: Image.asset(
                        AppAssets.onboardingWelcome,
                        height: 220,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Text(
              infoText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

