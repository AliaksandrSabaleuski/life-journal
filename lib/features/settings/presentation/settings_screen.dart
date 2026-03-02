import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _prefsUserNameKey = 'user_name';
  static const _prefsNotificationsKey = 'notifications_enabled';
  static const _prefsLanguageKey = 'app_language';

  static const _supportEmail = 'support@lifejournal.app';
  static const _appVersion = '1.0.0';

  String _userName = '';
  bool _notificationsEnabled = true;
  String _languageCode = 'ru';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString(_prefsUserNameKey) ?? '';
      _notificationsEnabled = prefs.getBool(_prefsNotificationsKey) ?? true;
      _languageCode = prefs.getString(_prefsLanguageKey) ?? 'ru';
      _loading = false;
    });
  }

  Future<void> _saveUserName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsUserNameKey, value);
  }

  Future<void> _saveNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsNotificationsKey, value);
  }

  Future<void> _saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLanguageKey, code);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayName = _userName.isEmpty ? 'Друг' : _userName;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Имя пользователя',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Изменить имя',
                        onPressed: _editUserName,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Вы супер!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Push‑уведомления'),
            subtitle: const Text('Напоминания о привычках и важные события'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveNotificationsEnabled(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Уведомления включены. Настройка конкретных типов появится позже.'
                        : 'Уведомления отключены. Вы сможете включить их снова в настройках.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.card_membership_outlined),
            title: const Text('Управление подпиской'),
            subtitle: const Text('Скоро здесь появится экран подписки'),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.subscriptionTitle),
                  content: Text(l.subscriptionBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l.closeButton),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Предложить улучшения'),
            onTap: _openFeedbackForm,
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Рассказать друзьям'),
            onTap: () {
              Share.share(
                'Я веду дневник привычек в приложении «Дневник привычек». Попробуй и ты!',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_rate_outlined),
            title: const Text('Поставить оценку'),
            onTap: _openStoreRating,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Язык приложения',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _LanguageChip(
                  code: 'ru',
                  label: 'Русский',
                  flag: '🇷🇺',
                  selected: _languageCode == 'ru',
                  onTap: () {
                    setState(() => _languageCode = 'ru');
                    _saveLanguage('ru');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Русский язык уже активен')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LanguageChip(
                  code: 'en',
                  label: 'English',
                  flag: '🇺🇸',
                  selected: _languageCode == 'en',
                  onTap: () {
                    setState(() => _languageCode = 'en');
                    _saveLanguage('en');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Английская локализация появится в одной из следующих версий.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Удалить аккаунт'),
            onTap: _confirmDeleteAccount,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Выход'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Функция выхода появится, когда добавим аккаунты.'),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Версия приложения'),
            subtitle: Text(_appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Условия пользования'),
            onTap: () => _openUrl(Uri.parse('https://example.com/terms')),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Политика конфиденциальности'),
            onTap: () => _openUrl(Uri.parse('https://example.com/privacy')),
          ),
        ],
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
                'Напишите нам на $_supportEmail или оставьте сообщение ниже.',
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
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Спасибо за обратную связь! Мы обязательно всё прочитаем.'),
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
    // TODO: заменить на реальные ссылки на сторы.
    const url = 'https://play.google.com/store';
    await _openUrl(Uri.parse(url));
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
        _languageCode = 'ru';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные на этом устройстве удалены.')),
      );
    }
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.code,
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
