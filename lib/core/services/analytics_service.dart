import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gameanalytics_sdk/gameanalytics.dart';

import 'appmetrica_service.dart';

/// Analytics service: GameAnalytics on Android for store builds.
/// No-op on other platforms or when not configured.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  bool _initialized = false;

  /// Initialize with Game Key and Secret Key from GameAnalytics dashboard.
  /// On non-Android or when keys are empty, stays no-op.
  Future<void> init({
    required String gameKey,
    required String secretKey,
  }) async {
    if (_initialized) return;
    if (kIsWeb || !Platform.isAndroid) return;
    if (gameKey.isEmpty || secretKey.isEmpty) return;

    try {
      GameAnalytics.configureAutoDetectAppVersion(true);
      await GameAnalytics.initialize(gameKey, secretKey);
      _initialized = true;
    } catch (_) {
      // Analytics init failed — stay no-op
    }
  }

  bool get _enabled => _initialized;

  void _designEvent(String eventId, [double? value]) {
    // GameAnalytics
    if (_enabled) {
      final args = <String, dynamic>{"eventId": eventId};
      if (value != null) args["value"] = value;
      GameAnalytics.addDesignEvent(args);
    }

    // AppMetrica (дублируем без value, как простой event)
    AppMetricaService.instance.reportEvent(
      eventId,
      attributes: value == null ? null : {'value': value},
    );
  }

  /// Log screen view (e.g. main, settings, subscription).
  Future<void> logScreenView({required String screenName}) async {
    _designEvent("screen:$screenName");
  }

  /// Log custom design event.
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    // Do not gate on _enabled: AppMetrica still receives via _designEvent when GA keys are missing.
    final parts = [name];
    if (parameters != null && parameters.isNotEmpty) {
      for (final e in parameters.entries) {
        if (e.value != null) parts.add("${e.key}:${e.value}");
      }
    }
    _designEvent(parts.join(":"));
  }

  // --- App-specific events ---

  Future<void> logHabitAdded({String? habitType}) async {
    _designEvent("habit_added:${habitType ?? 'unknown'}");
  }

  Future<void> logEventAdded({String? eventType}) async {
    _designEvent("event_added:${eventType ?? 'unknown'}");
  }

  Future<void> logHabitCompleted({String? habitId}) async {
    _designEvent("habit_completed", habitId != null ? 1 : 0);
  }

  Future<void> logSubscriptionScreenViewed() async {
    _designEvent("subscription_screen_viewed");
  }

  Future<void> logSubscriptionStarted({required String plan}) async {
    _designEvent("subscription_started:$plan");
  }

  Future<void> logPurchaseSuccess({required String plan}) async {
    _designEvent("purchase_success:$plan");
  }

  Future<void> logPurchaseFailed({required String plan, required String reason}) async {
    _designEvent("purchase_failed:$plan:$reason");
  }

  Future<void> logPurchaseUnavailable({String? where}) async {
    _designEvent("purchase_unavailable${where == null ? '' : ':$where'}");
  }

  Future<void> logRestoreStarted() async {
    _designEvent("restore_started");
  }

  Future<void> logRestoreSuccess() async {
    _designEvent("restore_success");
  }

  Future<void> logOnboardingCompleted() async {
    _designEvent("onboarding_completed");
  }

  Future<void> logShareTapped() async {
    _designEvent("share_tapped");
  }

  Future<void> logSettingsOpened() async {
    _designEvent("settings_opened");
  }
}
