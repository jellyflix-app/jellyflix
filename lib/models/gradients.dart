import 'package:flutter/material.dart';

class Gradients {
  static const List<List<Color>> gradients = [
    [Color(0xcc673ab7), Color(0xaa607d8b), Color(0xcc795548)],
    [Color(0xcc00bcd4), Color.fromARGB(170, 185, 25, 78), Color(0xcc795548)],
    [Color(0xcc00bcd4), Color(0xaa9c27b0), Color.fromARGB(204, 200, 67, 27)],
    [Color(0xcc4caf50), Color(0xaa795548), Color(0xcc673ab7)],
  ];

  static List<Color> getGradient(int index) {
    return gradients[index % gradients.length];
  }
}
