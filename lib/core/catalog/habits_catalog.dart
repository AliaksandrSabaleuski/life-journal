import 'dart:convert';

import 'package:flutter/services.dart';

import 'habit_template.dart';

class HabitsCatalog {
  const HabitsCatalog({
    required this.version,
    required this.freeLimits,
    required this.premiumLimits,
    required this.items,
  });

  final int version;
  final CatalogLimits freeLimits;
  final CatalogLimits premiumLimits;
  final List<HabitTemplate> items;

  Iterable<HabitTemplate> get habits => items.where((i) => !i.isEvent);
  Iterable<HabitTemplate> get events => items.where((i) => i.isEvent);

  static Future<HabitsCatalog> loadFromAsset([
    String assetPath = 'assets/catalog/habits_catalog.json',
  ]) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = (jsonDecode(raw) as Map).cast<String, Object?>();
    return HabitsCatalog.fromJson(json);
  }

  static HabitsCatalog fromJson(Map<String, Object?> json) {
    final limits = (json['limits'] as Map).cast<String, Object?>();
    final free = (limits['free'] as Map).cast<String, Object?>();
    final premium = (limits['premium'] as Map).cast<String, Object?>();
    final items = ((json['items'] as List?) ?? const <Object?>[])
        .map((e) => HabitTemplate.fromJson((e as Map).cast<String, Object?>()))
        .toList(growable: false);
    return HabitsCatalog(
      version: (json['version'] as num).toInt(),
      freeLimits: CatalogLimits.fromJson(free),
      premiumLimits: CatalogLimits.fromJson(premium),
      items: items,
    );
  }
}

