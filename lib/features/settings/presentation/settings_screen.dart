import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/iap_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../app/strings_ru.dart';
import '../../subscription/presentation/subscription_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _prefsUserNameKey = 'user_name';
  static const _prefsNotificationsKey = 'notifications_enabled';

  static const _defaultSupportEmail = 'alexgmlchn@gmail.com';
  static const _appVersion = '1.0.0';

  String _userName = '';
  bool _notificationsEnabled = true;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'settings');
    AnalyticsService.instance.logSettingsOpened();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw TimeoutException('SharedPreferences'),
      );
      if (!mounted) return;
      setState(() {
        _userName = prefs.getString(_prefsUserNameKey) ?? '';
        _notificationsEnabled = prefs.getBool(_prefsNotificationsKey) ?? true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveUserName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsUserNameKey, value);
  }

  Future<void> _saveNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsNotificationsKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const cardRadius = 14.0;
    const tilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    Widget settingsTile({
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap,
    }) {
      return Material(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(cardRadius),
          onTap: onTap,
          child: Padding(
            padding: tilePadding,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing,
                ] else ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    Widget blockTitle(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      );
    }

    Widget listShadowWrapper(Widget child) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: StringsRu.close,
        ),
        title: const Text(StringsRu.settings),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    children: [
                      blockTitle(
                        'Настрой приложение под себя\nи сделай привычки ещё удобнее.',
                      ),
                      const SizedBox(height: 6),

                      // Первая плитка со switch (как на рефе)
                      listShadowWrapper(
                        Material(
                          color: Colors.white.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(cardRadius),
                          child: Padding(
                            padding: tilePadding,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Push‑уведомления',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Напоминания о привычках и важные события',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _notificationsEnabled,
                                  onChanged: (value) {
                                    setState(() => _notificationsEnabled = value);
                                    _saveNotificationsEnabled(value);
                                    NotificationService.instance.setNotificationsEnabled(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Плитки-опции
                      listShadowWrapper(
                        settingsTile(
                          title: 'Управление подпиской',
                          onTap: () => SubscriptionScreen.show(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      listShadowWrapper(
                        settingsTile(
                          title: 'Восстановить покупки',
                          onTap: () async {
                            AnalyticsService.instance.logRestoreStarted();
                            final res = await IapService.instance.restore();
                            if (!mounted) return;
                            if (res == IapPurchaseResult.unavailable) {
                              AnalyticsService.instance.logPurchaseUnavailable(where: 'restore');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Восстановление недоступно')),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Проверяем покупки...')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      listShadowWrapper(
                        settingsTile(
                          title: 'Предложить улучшения',
                          onTap: _openFeedbackForm,
                        ),
                      ),
                      const SizedBox(height: 10),
                      listShadowWrapper(
                        settingsTile(
                          title: 'Рассказать друзьям',
                          onTap: () {
                            AnalyticsService.instance.logShareTapped();
                            Share.share(
                              'Я веду дневник привычек в приложении «${StringsRu.appTitle}». Попробуй и ты!',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      listShadowWrapper(
                        settingsTile(
                          title: 'Поставить оценку',
                          onTap: _openStoreRating,
                        ),
                      ),

                      const SizedBox(height: 16),
                      listShadowWrapper(
                        settingsTile(
                          title: 'Удалить аккаунт',
                          onTap: _confirmDeleteAccount,
                        ),
                      ),
                      const SizedBox(height: 10),
                      listShadowWrapper(
                        settingsTile(
                          title: 'Условия пользования',
                          onTap: () => _openUrl(Uri.parse(
                            'https://docs.google.com/document/d/1kzfe6FwYZZPCzmZlmNBBQy-0mg2y_C2PdtGoP7UNQ3w/view?usp=sharing',
                          )),
                        ),
                      ),
                      const SizedBox(height: 10),
                      listShadowWrapper(
                        settingsTile(
                          title: 'Политика конфиденциальности',
                          onTap: () => _openUrl(Uri.parse(
                            'https://docs.google.com/document/d/1jaLmnQvmo2GXfMC5_L6wCLwshuF2eGD8QdlfhQzPJjw/view?usp=sharing',
                          )),
                        ),
                      ),
                    ],
                  ),

                  // Версия внизу (как на рефе)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Text(
                        'Версия приложения $_appVersion',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _editUserName() async {
    final controller = TextEditingController(text: _userName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Имя пользователя'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Как к вам обращаться?',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _userName = result);
      await _saveUserName(result);
    }
  }

  Future<void> _openFeedbackForm() async {
    final controller = TextEditingController();
    const supportEmail = String.fromEnvironment(
      'SUPPORT_EMAIL',
      defaultValue: _defaultSupportEmail,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final padding = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, padding + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Будем рады вашим идеям и критике',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Напишите нам на $supportEmail или оставьте сообщение ниже.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Текст обращения',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final msg = controller.text.trim();
                  Navigator.of(ctx).pop();
                  final ok = await _sendFeedbackEmail(
                    toEmail: supportEmail,
                    message: msg,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Открылось письмо — отправьте его, пожалуйста.'
                            : 'Не удалось открыть почту на устройстве.',
                      ),
                    ),
                  );
                },
                child: const Text('Отправить'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openStoreRating() async {
    const androidPackage = 'app.zharptychgames.habitrun';
    final playWeb = Uri.parse(
      'https://play.google.com/store/apps/details?id=$androidPackage',
    );
    final playMarket = Uri.parse('market://details?id=$androidPackage');

    // Prefer Play app deep link on Android; fallback to web.
    if (!kIsWeb && Platform.isAndroid) {
      final ok = await launchUrl(
        playMarket,
        mode: LaunchMode.externalApplication,
      );
      if (ok) return;
    }
    await _openUrl(playWeb);
  }

  Future<void> _openUrl(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку')),
        );
      }
    }
  }

  Future<bool> _sendFeedbackEmail({
    required String toEmail,
    required String message,
  }) async {
    final platform = kIsWeb
        ? 'web'
        : (Platform.isAndroid
            ? 'android'
            : (Platform.isIOS
                ? 'ios'
                : (Platform.isWindows
                    ? 'windows'
                    : (Platform.isMacOS ? 'macos' : 'other'))));

    final subject = 'About Me — обратная связь';
    final body = [
      if (message.isNotEmpty) message,
      '',
      '---',
      'App: About Me',
      'Version: $_appVersion',
      'Platform: $platform',
    ].join('\n');

    final uri = Uri(
      scheme: 'mailto',
      path: toEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Мы удалим локальные данные приложения на этом устройстве. '
          'Отменить это действие будет нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      setState(() {
        _userName = '';
        _notificationsEnabled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные на этом устройстве удалены.')),
      );
    }
  }
}
