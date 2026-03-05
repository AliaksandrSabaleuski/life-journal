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
}

