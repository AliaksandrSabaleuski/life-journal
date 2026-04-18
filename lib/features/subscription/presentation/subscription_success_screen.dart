import 'package:flutter/material.dart';

/// Экран успешного оформления подписки — показывается после покупки.
class SubscriptionSuccessScreen extends StatelessWidget {
  const SubscriptionSuccessScreen({
    super.key,
    this.planName,
  });

  /// Название выбранного плана (7 дней бесплатно, ежемесячно, ежегодно).
  final String? planName;

  static const _coffee = Color(0xFF6B5A4E);
  static const _warmCard = Color(0xFFF6EEE5);

  @override
  Widget build(BuildContext context) {
    final planText = planName ?? 'Премиум';
    final theme = Theme.of(context);

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
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Container(
                      // Как на первом экране подписки: компактное "стекло" с теми же отступами/радиусом.
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        // В стиле первого экрана подписки: тёплое “стекло” без повторного бэка.
                        color: _warmCard.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
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
                        children: [
                          Text(
                            'ПОЗДРАВЛЯЕМ!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _coffee.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildCheckmarkIcon(),
                          const SizedBox(height: 32),
                          Text(
                            'Подписка оформлена на',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            planText,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: _coffee.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Отслеживайте свои успехи с неограниченным количеством целей.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
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

  Widget _buildCheckmarkIcon() {
    return Center(
      child: Image.asset(
        'assets/icons/CheckMark.png',
        width: 192,
        height: 192,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        child: const Text('Достигайте своих целей'),
      ),
    );
  }
}
