import 'package:flutter/material.dart';

class IconRegistry {
  static IconData? byKey(String? key) {
    if (key == null) return null;
    return switch (key) {
      'water_drop' => Icons.water_drop,
      'directions_walk' => Icons.directions_walk,
      'call' => Icons.call,
      'event_outlined' => Icons.event_outlined,
      'bed' => Icons.bed,
      'chat' => Icons.forum,
      'movie' => Icons.movie,
      'concert' => Icons.music_note,
      'museum' => Icons.museum,
      'work' => Icons.work,
      'rest' => Icons.beach_access,
      'cleanup' => Icons.cleaning_services,
      'date' => Icons.favorite,
      'flowers' => Icons.local_florist,
      'sleep' => Icons.nights_stay,
      'cold' => Icons.ac_unit,
      'breakfast' => Icons.free_breakfast,
      'lunch' => Icons.lunch_dining,
      'dinner' => Icons.dinner_dining,
      'progress' => Icons.trending_up,
      'learning' => Icons.school,
      'self_criticism' => Icons.psychology,
      'planning' => Icons.today,
      'goal_setting' => Icons.flag,
      'review' => Icons.checklist,
      'small_win' => Icons.emoji_events,
      'big_win' => Icons.emoji_events,
      'cook' => Icons.restaurant_menu,
      'tooth_brush' => Icons.brush,
      'bath' => Icons.bathtub,
      'hugs' => Icons.favorite_border,
      'meet' => Icons.people_alt,
      'shopping' => Icons.shopping_cart,
      'fruits' => Icons.local_grocery_store,
      'meditation' => Icons.self_improvement,
      'reading' => Icons.menu_book,
      'screen_limit' => Icons.phone_android,
      'sweets' => Icons.cake,
      _ => null,
    };
  }
}

