import 'package:flutter/material.dart';

class IconRegistry {
  static const Map<String, IconData> _iconsByKey = {
    'water_drop': Icons.water_drop,
    'directions_walk': Icons.directions_walk,
    'call': Icons.call,
    'event_outlined': Icons.event_outlined,
    'bed': Icons.bed,
    'chat': Icons.forum,
    'movie': Icons.movie,
    'concert': Icons.music_note,
    'museum': Icons.museum,
    'work': Icons.work,
    'rest': Icons.beach_access,
    'cleanup': Icons.cleaning_services,
    'date': Icons.favorite,
    'flowers': Icons.local_florist,
    'sleep': Icons.nights_stay,
    'cold': Icons.ac_unit,
    'breakfast': Icons.free_breakfast,
    'lunch': Icons.lunch_dining,
    'dinner': Icons.dinner_dining,
    'progress': Icons.trending_up,
    'learning': Icons.school,
    'self_criticism': Icons.psychology,
    'planning': Icons.today,
    'goal_setting': Icons.flag,
    'review': Icons.checklist,
    'small_win': Icons.emoji_events,
    'big_win': Icons.emoji_events,
    'cook': Icons.restaurant_menu,
    'tooth_brush': Icons.brush,
    'bath': Icons.bathtub,
    'hugs': Icons.favorite_border,
    'meet': Icons.people_alt,
    'shopping': Icons.shopping_cart,
    'fruits': Icons.local_grocery_store,
    'meditation': Icons.self_improvement,
    'reading': Icons.menu_book,
    'screen_limit': Icons.phone_android,
    'sweets': Icons.cake,
    'fitness_center': Icons.fitness_center,
    'local_bar': Icons.local_bar,
    'smoking_rooms': Icons.smoking_rooms,
    'sports_esports': Icons.sports_esports,
    'local_cafe': Icons.local_cafe,
  };

  static IconData? byKey(String? key) {
    if (key == null) return null;
    return _iconsByKey[key];
  }

  static String? keyByIcon(IconData? icon) {
    if (icon == null) return null;
    for (final e in _iconsByKey.entries) {
      final v = e.value;
      if (v.codePoint == icon.codePoint && v.fontFamily == icon.fontFamily) {
        return e.key;
      }
    }
    return null;
  }

  static String? keyByCodePoint(int codePoint, {String? fontFamily}) {
    for (final e in _iconsByKey.entries) {
      final v = e.value;
      if (v.codePoint == codePoint &&
          (fontFamily == null || v.fontFamily == fontFamily)) {
        return e.key;
      }
    }
    return null;
  }

  /// Все иконки, доступные для выбора в UI (привычки, события).
  static const List<IconData> allIcons = [
    Icons.star_rounded,
    Icons.water_drop,
    Icons.directions_walk,
    Icons.call,
    Icons.event_outlined,
    Icons.bed,
    Icons.forum,
    Icons.movie,
    Icons.music_note,
    Icons.museum,
    Icons.work,
    Icons.beach_access,
    Icons.cleaning_services,
    Icons.favorite,
    Icons.local_florist,
    Icons.nights_stay,
    Icons.ac_unit,
    Icons.free_breakfast,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.trending_up,
    Icons.school,
    Icons.psychology,
    Icons.today,
    Icons.flag,
    Icons.checklist,
    Icons.emoji_events,
    Icons.restaurant_menu,
    Icons.brush,
    Icons.bathtub,
    Icons.favorite_border,
    Icons.people_alt,
    Icons.shopping_cart,
    Icons.local_grocery_store,
    Icons.self_improvement,
    Icons.menu_book,
    Icons.phone_android,
    Icons.cake,
    Icons.fitness_center,
    Icons.local_bar,
    Icons.smoking_rooms,
    Icons.sports_esports,
    Icons.local_cafe,
    Icons.pets,
    Icons.thumb_up_rounded,
  ];
}

