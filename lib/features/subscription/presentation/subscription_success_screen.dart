import 'package:flutter/material.dart';

/// Экран успешного оформления подписки — показывается после покупки.
class SubscriptionSuccessScreen extends StatelessWidget {
  const SubscriptionSuccessScreen({
    super.key,
    this.planName,
  });

  /// Название выбранного плана (7 дней бесплатно, ежемесячно, ежегодно).
  final String? planName;

  static const _purpleLight = Color(0xFFB8A4E0);
  static const _purpleStart = Color(0xFF6B4EAA);
  static const _purpleEnd = Color(0xFF9B7EDE);

  @override
  Widget build(BuildContext context) {
    final planText = planName ?? 'Премиум';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/subscription_passed_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ПОЗДРАВЛЯЕМ!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: _purpleLight,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildCheckmarkCircle(),
                          const SizedBox(height: 32),
                          const Text(
                            'Подписка оформлена на',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            planText,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Отслеживайте свои успехи с неограниченным количеством целей.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade400,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Раскрой свой потенциал!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    _buildCtaButton(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckmarkCircle() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purpleStart, _purpleEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _purpleEnd.withValues(alpha: 0.6),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        size: 64,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _purpleEnd.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            child: const Text(
              'ДОСТИГАЙТЕ СВОИХ ЦЕЛЕЙ',
              textAlign: TextAlign.center,
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
    );
  }
}
