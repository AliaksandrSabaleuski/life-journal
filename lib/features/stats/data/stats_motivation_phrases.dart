import 'dart:math';

import 'package:flutter/material.dart';

/// Короткие мотивационные фразы для экрана статистики.
/// Выбор случайного индекса — O(1), без I/O.
abstract final class StatsMotivationPhrases {
  static const _ru = <String>[
    'Ты на правильном пути!',
    'Каждый день — маленький шаг вперёд.',
    'Ты сильнее, чем вчера.',
    'Маленькие победы складываются в большой результат.',
    'Продолжай — уже виден прогресс.',
    'Ты держишь курс — это главное.',
    'Стабильность важнее идеала.',
    'Сегодня ты уже сделал(а) достаточно.',
    'Привычка — это то, что ты выбираешь снова и снова.',
    'Твоё упорство работает на тебя.',
  ];

  static const _en = <String>[
    "You're on the right track!",
    'Every day is a small step forward.',
    "You're stronger than yesterday.",
    'Small wins add up to big results.',
    'Keep going — progress is showing.',
    "You're staying on course — that matters.",
    'Consistency beats perfection.',
    "Today you've already done enough.",
    'A habit is what you choose again and again.',
    'Your persistence is paying off.',
  ];

  static List<String> _listFor(Locale locale) =>
      locale.languageCode == 'en' ? _en : _ru;

  /// Случайная фраза под текущую локаль.
  static String pick(Locale locale, {Random? random}) {
    final list = _listFor(locale);
    final r = random ?? Random();
    return list[r.nextInt(list.length)];
  }
}
