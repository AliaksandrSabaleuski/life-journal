import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/iap_service.dart';
import '../../../../core/services/subscription_service.dart';

/// План подписки.
enum SubscriptionPlan {
  trial,
  annual,
  lifetime,
}

/// Полноэкранное окно подписки в стиле макета: тёмная тема, градиенты, карточки планов.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    super.key,
    this.limitMessage,
  });

  /// Сообщение о достижении лимита (если открыто из-за ограничения).
  final String? limitMessage;

  static Future<void> show(
    BuildContext context, {
    String? limitMessage,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => SubscriptionScreen(limitMessage: limitMessage),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.trial;
  bool _isAnnualSelected = true; // «Выгоднее» — годовой выбран по умолчанию

  static const _purpleStart = Color(0xFF6B4EAA);
  static const _warmCard = Color(0xFFF6EEE5);
  static const _warmCardBorder = Color(0xFFFFFFFF);
  static const _coffee = Color(0xFF6B5A4E); // как в MainShell
  static const _badgeGreen = Color(0xFF2E7D32);

  VoidCallback? _premiumListener;

  String _appTitle(BuildContext context) {
    final title = context.findAncestorWidgetOfExactType<MaterialApp>()?.title;
    if (title != null && title.trim().isNotEmpty) return title.trim();
    return 'About Me';
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logSubscriptionScreenViewed();
    _premiumListener = () {
      if (SubscriptionService.isPremium && mounted) {
        setState(() {});
      }
    };
    SubscriptionService.isPremiumNotifier.addListener(_premiumListener!);
  }

  @override
  void dispose() {
    if (_premiumListener != null) {
      SubscriptionService.isPremiumNotifier.removeListener(_premiumListener!);
    }
    super.dispose();
  }

  static const _purpleEnd = Color(0xFF9B7EDE);
  static const _bgDark = Color(0xFF1A1A2E); // оставим для других элементов, если нужно
  static const _cardDark = Color(0xFF252538);
  static const _cardBorder = Color(0xFF3D3D5C);
  static const _ctaRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final isPremium = SubscriptionService.isPremium;
    final appName = _appTitle(context);
    final theme = Theme.of(context);

    if (isPremium) {
      return _buildPremiumThanks(context, appName: appName);
    }

    final iap = IapService.instance;
    final prices = iap.pricingSnapshot();
    final trialPrice = (prices?['trialLine'] as String?) ??
        '0 ₽ сегодня, затем 30 ₽ / месяц';
    final annualPrice = (prices?['annualPrice'] as String?) ?? '2 390 ₽ / год';
    final annualOldPrice = (prices?['annualOldPrice'] as String?) ?? '5 975 ₽ / год';
    final annualBenefit = (prices?['annualBenefit'] as int?) ?? 60;
    final lifetimePrice = (prices?['lifetimeLine'] as String?) ??
        '2 990 ₽ — единоразово';

    return ValueListenableBuilder<int>(
      valueListenable: iap.productsVersion,
      builder: (context, _, __) {
        final prices2 = iap.pricingSnapshot();
        final trialPrice2 = (prices2?['trialLine'] as String?) ?? trialPrice;
        final annualPrice2 = (prices2?['annualPrice'] as String?) ?? annualPrice;
        final annualOldPrice2 =
            (prices2?['annualOldPrice'] as String?) ?? annualOldPrice;
        final annualBenefit2 = (prices2?['annualBenefit'] as int?) ?? annualBenefit;
        final lifetimePrice2 =
            (prices2?['lifetimeLine'] as String?) ?? lifetimePrice;

        return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/subscription_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        decoration: BoxDecoration(
                          color: _warmCard.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _warmCardBorder.withValues(alpha: 0.55),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Получите доступ к $appName без ограничений',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _coffee.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Раскройте свой потенциал и отслеживайте прогресс\nбез ограничений',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (widget.limitMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer
                                      .withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  widget.limitMessage!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _buildPlanCard(
                              plan: SubscriptionPlan.trial,
                              title: '7 дней бесплатно',
                              price: trialPrice2,
                              isSelected: _selectedPlan == SubscriptionPlan.trial,
                              onTap: () => setState(() => _selectedPlan = SubscriptionPlan.trial),
                            ),
                            const SizedBox(height: 10),
                            _buildPlanCard(
                              plan: SubscriptionPlan.annual,
                              title: 'Ежегодно',
                              price: annualPrice2,
                              oldPrice: annualOldPrice2,
                              isSelected: _selectedPlan == SubscriptionPlan.annual,
                              badge: 'Выгода $annualBenefit2%',
                              onTap: () => setState(() {
                                _selectedPlan = SubscriptionPlan.annual;
                                _isAnnualSelected = true;
                              }),
                            ),
                            const SizedBox(height: 10),
                            _buildPlanCard(
                              plan: SubscriptionPlan.lifetime,
                              title: 'Навсегда',
                              price: lifetimePrice2,
                              isSelected: _selectedPlan == SubscriptionPlan.lifetime,
                              onTap: () => setState(() {
                                _selectedPlan = SubscriptionPlan.lifetime;
                                _isAnnualSelected = false;
                              }),
                            ),
                            const SizedBox(height: 14),
                            _buildContinueButton(),
                            const SizedBox(height: 10),
                            if (_selectedPlan == SubscriptionPlan.trial) _buildDisclaimer(),
                            if (kDebugMode && !kIsWeb && Platform.isWindows) ...[
                              const SizedBox(height: 10),
                              _buildWindowsDebugPurchaseTools(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Закрыть',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required String title,
    required String price,
    String? oldPrice,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final border = theme.colorScheme.outline.withValues(alpha: 0.35);
    final fill = Colors.white.withValues(alpha: 0.62);
    final selectedFill = primary.withValues(alpha: 0.16);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedFill : fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary.withValues(alpha: 0.55) : border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _coffee.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (oldPrice == null)
                        Text(
                          price,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Text(
                              price,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              oldPrice,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.65),
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _badgeGreen.withValues(alpha: 0.16)
                        : _badgeGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _badgeGreen.withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _badgeGreen,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return _PrimaryCtaButton(
      label: 'Продолжить',
      onPressed: _onContinue,
    );
  }

  Widget _buildDisclaimer() {
    return Text(
      'Отмена в пробный период. Автопродление. Подробнее в Условиях и Политике.',
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade500,
        height: 1.3,
      ),
    );
  }

  Widget _buildWindowsDebugPurchaseTools() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Windows debug',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: _coffee.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await SubscriptionService.setDebugPremium(true);
                    if (mounted) setState(() {});
                  },
                  child: const Text('Включить premium'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await SubscriptionService.setDebugPremium(false);
                    if (mounted) setState(() {});
                  },
                  child: const Text('Выключить premium'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await SubscriptionService.clearDebugPremium();
              if (mounted) setState(() {});
            },
            child: const Text('Сбросить override'),
          ),
        ],
      ),
    );
  }

  Future<void> _onContinue() async {
    final planName = _planNameForSelected();
    AnalyticsService.instance.logSubscriptionStarted(plan: planName);

    final iap = IapService.instance;
    if (iap.isAvailable) {
      final result = await iap.purchasePlan(_iapPlanKey());
      switch (result) {
        case IapPurchaseResult.started:
          // Purchase UI opened. When done, _onPurchaseUpdate will set premium
          // and listener will trigger setState → build shows thanks.
          return;
        case IapPurchaseResult.productNotFound:
          AnalyticsService.instance.logPurchaseFailed(
            plan: planName,
            reason: 'product_not_found',
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Продукты подписки ещё не настроены. Попробуйте позже.')),
          );
          return;
        case IapPurchaseResult.unavailable:
          AnalyticsService.instance.logPurchaseUnavailable(where: 'iap');
          AnalyticsService.instance.logPurchaseFailed(
            plan: planName,
            reason: 'unavailable',
          );
        case IapPurchaseResult.failed:
          AnalyticsService.instance.logPurchaseFailed(
            plan: planName,
            reason: 'failed_to_start',
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Покупка недоступна. Проверьте подключение к Google Play.')),
          );
          return;
      }
    }

    AnalyticsService.instance.logPurchaseUnavailable(where: 'no_iap');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Покупка сейчас недоступна. Откройте приложение из Google Play или попробуйте позже.',
        ),
      ),
    );
  }

  String _planNameForSelected() {
    switch (_selectedPlan) {
      case SubscriptionPlan.trial:
        return '7 дней бесплатно';
      case SubscriptionPlan.annual:
        return 'Ежегодно';
      case SubscriptionPlan.lifetime:
        return 'Навсегда';
    }
  }

  String _iapPlanKey() {
    switch (_selectedPlan) {
      case SubscriptionPlan.annual:
        return 'yearly';
      case SubscriptionPlan.lifetime:
        return 'lifetime';
      case SubscriptionPlan.trial:
        return 'trial_monthly';
    }
  }

  Widget _buildPremiumThanks(BuildContext context, {required String appName}) {
    final theme = Theme.of(context);
    // Как в `MainShell` для заголовка главного меню (“Сегодня” / дата).
    const coffee = Color(0xFF6B5A4E);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/subscripded_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'У вас доступ к $appName без ограничений!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: coffee.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Отслеживайте свои успехи с неограниченным количеством целей.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Раскрой свой потенциал!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    _PrimaryCtaButton(
                      label: 'Продолжить',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Закрыть',
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCtaButton extends StatelessWidget {
  const _PrimaryCtaButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_SubscriptionScreenState._ctaRadius),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
