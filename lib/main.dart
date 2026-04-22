import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/ga_keys.dart';
import 'core/services/analytics_service.dart';
import 'core/services/appmetrica_service.dart';
import 'core/services/dev_reset_service.dart';
import 'core/services/iap_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/subscription_service.dart';

Future<({String gameKey, String secretKey})?> _loadGaKeysFromDisk() async {
  // Local-only convenience: keep secrets outside the repo.
  // Accept both names (Windows may append .txt).
  const candidates = [
    r'D:\keystore\key\ga_keys.json',
    r'D:\keystore\key\ga_keys.json.txt',
  ];
  for (final path in candidates) {
    final f = File(path);
    if (!await f.exists()) continue;
    try {
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) continue;
      final gameKey = decoded['gameKey'];
      final secretKey = decoded['secretKey'];
      if (gameKey is String && secretKey is String) {
        return (gameKey: gameKey.trim(), secretKey: secretKey.trim());
      }
    } catch (_) {
      // ignore bad file
    }
  }
  return null;
}

Future<String?> _loadAppMetricaKeyFromDisk() async {
  const candidates = [
    r'D:\keystore\key\appmetrica.json',
    r'D:\keystore\key\appmetrica.json.txt',
  ];
  for (final path in candidates) {
    final f = File(path);
    if (!await f.exists()) continue;
    try {
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) continue;
      final apiKey = decoded['apiKey'];
      if (apiKey is String && apiKey.trim().isNotEmpty) {
        return apiKey.trim();
      }
    } catch (_) {
      // ignore bad file
    }
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DEV ONLY: всегда начинать "с нуля" при каждом запуске.
  await DevResetService.resetAll();

  // Intl: форматирование дат/дней недели на русском.
  await initializeDateFormatting('ru');

  // GameAnalytics: configure in lib/core/config/ga_keys.dart or via --dart-define
  final diskKeys = await _loadGaKeysFromDisk();
  const envGameKey = String.fromEnvironment('GA_GAME_KEY', defaultValue: gaGameKey);
  const envSecretKey = String.fromEnvironment('GA_SECRET_KEY', defaultValue: gaSecretKey);
  final gameKey = (diskKeys?.gameKey.isNotEmpty ?? false) ? diskKeys!.gameKey : envGameKey;
  final secretKey =
      (diskKeys?.secretKey.isNotEmpty ?? false) ? diskKeys!.secretKey : envSecretKey;
  await AnalyticsService.instance.init(gameKey: gameKey, secretKey: secretKey);

  // AppMetrica: configure via D:\keystore\key\appmetrica.json or --dart-define.
  final diskAppMetricaKey = await _loadAppMetricaKeyFromDisk();
  const envAppMetricaKey = String.fromEnvironment('APPMETRICA_API_KEY', defaultValue: '');
  final appMetricaKey =
      (diskAppMetricaKey?.isNotEmpty ?? false) ? diskAppMetricaKey! : envAppMetricaKey;
  await AppMetricaService.instance.init(apiKey: appMetricaKey);

  await NotificationService.instance.init();
  await NotificationService.instance.onAppOpened();
  await SubscriptionService.init();
  await IapService.instance.init();

  await SharedPreferences.getInstance();

  final completed = await OnboardingService.isCompleted();
  runApp(JournalApp(onboardingCompleted: completed));
}
