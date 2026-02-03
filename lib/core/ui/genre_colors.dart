import 'package:flutter/material.dart';

class GenreColorHelper {
  static Color getColor(String genre) {
    final g = genre.toLowerCase();

    if (g.contains('rock')) return Colors.redAccent;
    if (g.contains('metal')) return Colors.deepOrange;
    if (g.contains('pop')) return Colors.pinkAccent;
    if (g.contains('jazz')) return Colors.purpleAccent;
    if (g.contains('hip')) return Colors.orangeAccent;
    if (g.contains('rap')) return Colors.orange;
    if (g.contains('electronic') || g.contains('edm'))
      return Colors.blueAccent;
    if (g.contains('dance')) return Colors.cyan;
    if (g.contains('classical') || g.contains('clássica'))
      return Colors.amber;
    if (g.contains('reggae')) return Colors.green;
    if (g.contains('latin')) return Colors.teal;
    if (g.contains('blues')) return Colors.indigo;
    if (g.contains('country')) return Colors.brown;

    return Colors.blueGrey;
  }
}
