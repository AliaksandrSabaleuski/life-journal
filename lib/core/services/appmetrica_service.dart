import 'dart:io';

import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';

/// AppMetrica analytics (Android only).
///
/// Init is a no-op when apiKey is empty or platform is not Android.
class AppMetricaService {
  AppMetricaService._();

  static final AppMetricaService instance = AppMetricaService._();

  bool _initialized = false;

  Future<void> init({required String apiKey}) async {
    if (_initialized) return;
    if (kIsWeb || !Platform.isAndroid) return;
    if (apiKey.trim().isEmpty) return;
    try {
      AppMetrica.activate(AppMetricaConfig(apiKey.trim()));
      _initialized = true;
    } catch (_) {
      // stay no-op
    }
  }

  bool get _enabled => _initialized;

  void reportEvent(String name, {Map<String, Object?>? attributes}) {
    if (!_enabled) return;
    if (attributes == null || attributes.isEmpty) {
      AppMetrica.reportEvent(name);
      return;
    }

    final map = <String, Object>{};
    attributes.forEach((key, value) {
      if (value == null) return;
      // AppMetrica Flutter plugin accepts only non-null Map<String, Object>
      // that can be JSON-encoded.
      map[key] = value;
    });

    AppMetrica.reportEventWithMap(name, map.isEmpty ? null : map);
  }
}

