import 'package:flutter/material.dart';

class ColorRegistry {
  static Color byKey(String key) {
    return switch (key) {
      'lightBlueAccent' => Colors.lightBlueAccent,
      'greenAccent' => Colors.greenAccent,
      'lightBlue' => Colors.lightBlue,
      'orange' => Colors.orange,
      'redAccent' => Colors.redAccent,
      'purple' => Colors.purple,
      'pinkAccent' => Colors.pinkAccent,
      'teal' => Colors.teal,
      'amber' => Colors.amber,
      'deepPurple' => Colors.deepPurple,
      'indigo' => Colors.indigo,
      'cyan' => Colors.cyan,
      'brown' => Colors.brown,
      _ => Colors.blueGrey,
    };
  }

  /// Все цвета, доступные для выбора в UI (привычки, события).
  static const List<Color> allColors = [
    Colors.green,
    Colors.greenAccent,
    Colors.lightBlue,
    Colors.lightBlueAccent,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.deepPurple,
    Colors.orange,
    Colors.amber,
    Colors.red,
    Colors.redAccent,
    Colors.pink,
    Colors.pinkAccent,
    Colors.teal,
    Colors.cyan,
    Colors.brown,
  ];
}

