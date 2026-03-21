import 'package:flutter/material.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/iap_service.dart';
import '../../../../core/services/subscription_service.dart';
import 'subscription_success_screen.dart';

/// План подписки.
enum SubscriptionPlan {
  trial,
  monthly,
  annual,
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

  VoidCallback? _premiumListener;

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
  static const _bgDark = Color(0xFF1A1A2E);
  static const _cardDark = Color(0xFF252538);
  static const _cardBorder = Color(0xFF3D3D5C);

  @override
  Widget build(BuildContext context) {
    final isPremium = SubscriptionService.isPremium;

    if (isPremium) {
      return _buildPremiumThanks(context);
    }

    return Scaffold(
      backgroundColor: _bgDark,
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Получите доступ к Habit Run без ограничений',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Раскройте свой потенциал и отслеживайте прогресс без ограничений',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.limitMessage != null) ...[
                          const SizedBox(height: 10),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.limitMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade200,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        const SizedBox(height: 14),
                        _buildPlanCard(
                            plan: SubscriptionPlan.trial,
                            icon: Icons.card_giftcard,
                            title: 'Попробовать 7 дней бесплатно',
                            price: '0,00 ₽ сегодня',
                            isSelected: _selectedPlan == SubscriptionPlan.trial,
                          onTap: () => setState(() => _selectedPlan = SubscriptionPlan.trial),
                        ),
                        const SizedBox(height: 8),
                        _buildPlanCard(
                            plan: SubscriptionPlan.monthly,
                            title: 'Ежемесячно',
                            price: '299 ₽ / месяц',
                            isSelected: _selectedPlan == SubscriptionPlan.monthly,
                          onTap: () => setState(() {
                            _selectedPlan = SubscriptionPlan.monthly;
                            _isAnnualSelected = false;
                          }),
                        ),
                        const SizedBox(height: 8),
                        _buildPlanCard(
                            plan: SubscriptionPlan.annual,
                            title: 'Ежегодно',
                            price: '199 ₽ / месяц (2 390 ₽ год)',
                            isSelected: _selectedPlan == SubscriptionPlan.annual,
                            badge: 'Выгоднее',
                          onTap: () => setState(() {
                            _selectedPlan = SubscriptionPlan.annual;
                            _isAnnualSelected = true;
                          }),
                        ),
                        const SizedBox(height: 14),
                        _buildContinueButton(),
                        const SizedBox(height: 10),
                        _buildDisclaimer(),
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
                    icon: const Icon(Icons.close, color: Colors.white70),
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

  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required String title,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_purpleStart, _purpleEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : _cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : _cardBorder,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 20),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : Colors.white60,
                        ),
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
                    color: isSelected ? Colors.white24 : _purpleStart.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white54 : _purpleEnd,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purpleStart, _purpleEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _purpleEnd.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onContinue,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              'Продолжить',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
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

  Future<void> _onContinue() async {
    final planName = _planNameForSelected();
    AnalyticsService.instance.logSubscriptionStarted(plan: planName);

    final iap = IapService.instance;
    if (iap.isAvailable) {
      final result = await iap.purchase(planName);
      switch (result) {
        case IapPurchaseResult.started:
          // Purchase UI opened. When done, _onPurchaseUpdate will set premium
          // and listener will trigger setState → build shows thanks.
          return;
        case IapPurchaseResult.productNotFound:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Продукты подписки ещё не настроены. Попробуйте позже.')),
          );
          return;
        case IapPurchaseResult.unavailable:
        case IapPurchaseResult.failed:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Покупка недоступна. Проверьте подключение к Google Play.')),
          );
          return;
      }
    }

    // Fallback: внутреннее тестирование без настроенных продуктов
    await SubscriptionService.upgradeToPremium();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SubscriptionSuccessScreen(planName: planName),
        fullscreenDialog: true,
      ),
    );
  }

  String _planNameForSelected() {
    switch (_selectedPlan) {
      case SubscriptionPlan.trial:
        return '7 дней бесплатно';
      case SubscriptionPlan.monthly:
        return 'Ежемесячно';
      case SubscriptionPlan.annual:
        return 'Ежегодно';
    }
  }

  Widget _buildPremiumThanks(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/subscribed_bg.png',
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
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'У вас доступ к Habit Run без ограничений!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Отслеживайте свои успехи с неограниченным количеством целей.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade300,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Раскрой свой потенциал!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: _purpleEnd.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    _buildContinueButtonPremium(context),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
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

  Widget _buildContinueButtonPremium(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purpleStart, _purpleEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _purpleEnd.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox(
            height: 56,
            child: Center(
              child: Text(
                'ПРОДОЛЖИТЬ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
