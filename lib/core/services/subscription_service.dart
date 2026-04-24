import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../catalog/habit_template.dart';
import '../catalog/habits_catalog.dart';
import '../models/habit.dart';

/// Сервис подписки: хранит статус premium в SharedPreferences после покупки / restore.
class SubscriptionService {
  SubscriptionService._();

  static const String _premiumKey = 'subscription_premium';
  static const String _debugPremiumKey = 'subscription_premium_debug';

  static final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(false);
  static bool _loaded = false;

  static HabitsCatalog? _catalog;
  static CatalogLimits? _cachedFreeLimits;
  static CatalogLimits? _cachedPremiumLimits;

  static Future<void> init() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    var premium = prefs.getBool(_premiumKey) ?? false;

    // Windows debug convenience: allow toggling premium without store.
    if (kDebugMode && !kIsWeb && Platform.isWindows) {
      final debugValue = prefs.getBool(_debugPremiumKey);
      if (debugValue != null) premium = debugValue;
    }

    isPremiumNotifier.value = premium;
    _loaded = true;
    await _ensureCatalogLoaded();
  }

  static Future<void> _ensureCatalogLoaded() async {
    if (_catalog != null) return;
    try {
      _catalog = await HabitsCatalog.loadFromAsset();
      _cachedFreeLimits = _catalog!.freeLimits;
      _cachedPremiumLimits = _catalog!.premiumLimits;
    } catch (_) {
      // Fallback limits if catalog fails
      _cachedFreeLimits = const CatalogLimits(maxHabits: 6, maxEvents: 6);
      _cachedPremiumLimits = const CatalogLimits(maxHabits: 999, maxEvents: 999);
    }
  }

  static bool get isPremium => isPremiumNotifier.value;

  static CatalogLimits get freeLimits {
    if (_cachedFreeLimits != null) return _cachedFreeLimits!;
    return const CatalogLimits(maxHabits: 6, maxEvents: 6);
  }

  static CatalogLimits get premiumLimits {
    if (_cachedPremiumLimits != null) return _cachedPremiumLimits!;
    return const CatalogLimits(maxHabits: 999, maxEvents: 999);
  }

  static CatalogLimits get currentLimits =>
      isPremium ? premiumLimits : freeLimits;

  static Future<void> upgradeToPremium() async {
    if (isPremiumNotifier.value) return;
    isPremiumNotifier.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, true);
  }

  /// Debug-only override for Windows builds: simulates subscription purchase.
  /// Safe no-op outside Windows debug.
  static Future<void> setDebugPremium(bool value) async {
    if (!kDebugMode) return;
    if (kIsWeb) return;
    if (!Platform.isWindows) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugPremiumKey, value);
    isPremiumNotifier.value = value;
    // Keep the legacy key in sync for convenience when debugging other flows.
    await prefs.setBool(_premiumKey, value);
  }

  static Future<void> clearDebugPremium() async {
    if (!kDebugMode) return;
    if (kIsWeb) return;
    if (!Platform.isWindows) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_debugPremiumKey);
    // Fall back to stored "real" premium flag.
    final premium = prefs.getBool(_premiumKey) ?? false;
    isPremiumNotifier.value = premium;
  }

  /// Общее количество записей (привычек + событий).
  static int _totalCount(List<Habit> habits) => habits.where((h) => h.isActive).length;

  /// Можно ли добавить ещё одну запись (привычку или событие).
  /// Бесплатный тариф: максимум 6 записей. При попытке добавить 7-ю показываем подписку.
  static Future<bool> canAddHabit(List<Habit> existingHabits) async {
    await _ensureCatalogLoaded();
    final limits = currentLimits;
    return _totalCount(existingHabits) < limits.maxHabits;
  }

  /// Можно ли добавить ещё одно событие (тот же лимит — 6 записей всего).
  static Future<bool> canAddEvent(List<Habit> existingHabits) async =>
      canAddHabit(existingHabits);

  /// Можно ли добавить элемент указанного типа (привычка или событие).
  static Future<bool> canAdd(List<Habit> existingHabits, {required bool isEvent}) =>
      canAddHabit(existingHabits);

  /// Текст, поясняющий почему нельзя добавить.
  static String getLimitReachedMessage(bool isEvent) {
    final limits = currentLimits;
    return 'Достигнут лимит (${limits.maxHabits} записей). Оформите подписку для снятия ограничений.';
  }
}
