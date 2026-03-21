import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/catalog/habits_catalog.dart';
import '../../../core/catalog/color_registry.dart';
import '../../../core/catalog/icon_registry.dart';
import '../../../core/repositories/habits_repository.dart';
import '../../shell/presentation/main_shell.dart';

/// Цвета стиля приветственного экрана (розовый/бирюзовый/оранжевый).
class _OnboardingColors {
  static const Color pink = Color(0xFFE91E8C);
  static const Color pinkLight = Color(0xFFFFC8E3);
  static const Color pinkIcon = Color(0xFFF8BBD9);
  static const Color teal = Color(0xFF00897B);
  static const Color tealLight = Color(0xFF80CBC4);
  static const Color orange = Color(0xFFFF9800);
}

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
    final isDark = theme.brightness == Brightness.dark;

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
      footer = const _SettingsDisclaimer();
    } else {
      buttonText = _busy ? '...' : 'Продолжить';
      content = const _NotificationsCard();
    }

    final pinkBg = isDark
        ? Colors.pink.shade900.withValues(alpha: 0.15)
        : Colors.pink.shade50;
    return Scaffold(
      backgroundColor: pinkBg, // Все шаги онбординга с розовым фоном
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: content,
                  ),
                ),
              ),
              if (footer != null && (_step == 0 || _step == 1)) ...[
                footer!,
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: _step == 0 || _step == 1
                    ? FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : FilledButton(
                        onPressed: _busy ? null : _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: _OnboardingColors.pink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

/// Первый экран: дерево, птицы, заголовок «Добро пожаловать в», описание.
class _SplashCard extends StatelessWidget {
  const _SplashCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        // Декоративные птицы в правом верхнем углу
        Positioned(
          top: 0,
          right: 0,
          child: SizedBox(
            width: 80,
            height: 60,
            child: _BirdsSilhouette(
              color: theme.brightness == Brightness.dark
                  ? Colors.pink.shade300.withValues(alpha: 0.6)
                  : Colors.pink.shade200.withValues(alpha: 0.8),
            ),
          ),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(
                  child: SizedBox(
                    width: 120,
                    height: 160,
                    child: _TreeSilhouette(),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'ДОБРО ПОЖАЛОВАТЬ В',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ДНЕВНИК ПРИВЫЧЕК',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Начните путешествие против своих слабостей и зависимостей. '
                  'А данное приложение поможет вам отслеживать прогресс на протяжении всего пути '
                  'и становиться лучшей версией себя.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? theme.colorScheme.onSurface
                        : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Лёгкие силуэты птиц (ласточки) в правом верхнем углу.
class _BirdsSilhouette extends StatelessWidget {
  const _BirdsSilhouette({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 60),
      painter: _BirdsPainter(color: color),
    );
  }
}

class _BirdsPainter extends CustomPainter {
  _BirdsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Ласточка — классическая форма «V» с изгибом
    void drawBird(double x, double y, double scale) {
      final path = Path();
      path.moveTo(x - 6 * scale, y);
      path.quadraticBezierTo(
        x - 2 * scale, y - 6 * scale,
        x + 6 * scale, y,
      );
      path.quadraticBezierTo(
        x - 2 * scale, y + 6 * scale,
        x - 6 * scale, y,
      );
      canvas.drawPath(path, paint);
    }

    drawBird(45, 10, 1.0);
    drawBird(55, 6, 0.85);
    drawBird(65, 14, 0.7);
    drawBird(38, 20, 0.75);
    drawBird(52, 26, 0.6);
    drawBird(62, 32, 0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Силуэт дерева (хвойное).
class _TreeSilhouette extends StatelessWidget {
  const _TreeSilhouette();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return CustomPaint(
      size: const Size(120, 160),
      painter: _TreePainter(color: color),
    );
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Ствол
    final trunkWidth = w * 0.15;
    final trunkHeight = h * 0.2;
    final trunkLeft = (w - trunkWidth) / 2;
    final trunkTop = h - trunkHeight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(trunkLeft, trunkTop, trunkWidth, trunkHeight),
        const Radius.circular(2),
      ),
      paint,
    );

    // Крона — три треугольника (ярусы)
    final cx = w / 2;
    final baseY = trunkTop;
    // Нижний ярус
    final path1 = Path()
      ..moveTo(cx, baseY - h * 0.25)
      ..lineTo(cx - w * 0.42, baseY)
      ..lineTo(cx + w * 0.42, baseY)
      ..close();
    canvas.drawPath(path1, paint);
    // Средний ярус
    final path2 = Path()
      ..moveTo(cx, baseY - h * 0.55)
      ..lineTo(cx - w * 0.35, baseY - h * 0.28)
      ..lineTo(cx + w * 0.35, baseY - h * 0.28)
      ..close();
    canvas.drawPath(path2, paint);
    // Верхний ярус
    final path3 = Path()
      ..moveTo(cx, baseY - h * 0.8)
      ..lineTo(cx - w * 0.25, baseY - h * 0.58)
      ..lineTo(cx + w * 0.25, baseY - h * 0.58)
      ..close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Подпись: «Вы сможете поменять это позже в Настройки».
class _SettingsDisclaimer extends StatelessWidget {
  const _SettingsDisclaimer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Вы сможете поменять это позже в приложении «Настройки»',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
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
        ),
        TextSpan(
          children: [
            const TextSpan(text: 'Используя приложение, вы соглашаетесь с '),
            TextSpan(
              text: 'Политикой конфиденциальности',
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
            const TextSpan(text: ' и '),
            TextSpan(
              text: 'Правилами пользования',
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка приветствия: светло-розовый фон, птицы, заголовок, три карточки с иконками.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: SizedBox(
            width: 80,
            height: 60,
            child: _BirdsSilhouette(
              color: theme.brightness == Brightness.dark
                  ? Colors.pink.shade300.withValues(alpha: 0.6)
                  : Colors.pink.shade200.withValues(alpha: 0.8),
            ),
          ),
        ),
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Добро пожаловать в ваш дневник!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 24),
              _WelcomeFeatureCard(
                icon: Icons.menu_book_rounded,
                title: 'Сохраняйте моменты, важные для вас',
                subtitle: 'Наблюдайте за тем, как вы меняетесь и растете',
              ),
              const SizedBox(height: 16),
              _WelcomeFeatureCard(
                icon: Icons.lock_outline_rounded,
                title: 'Храните свои мысли и идеи в тайне',
                subtitle: 'Дневник только для ваших глаз',
              ),
              const SizedBox(height: 16),
              _WelcomeFeatureCard(
                icon: Icons.bar_chart_rounded,
                title: 'Отслеживайте свои эмоции',
                subtitle: 'Отмечайте свои настроения и выявляйте закономерности',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeFeatureCard extends StatelessWidget {
  const _WelcomeFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.pink, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          for (final f in features) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(f.icon, color: Colors.pink, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    f.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const Spacer(),
          Text(
            infoText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

