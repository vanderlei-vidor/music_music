// core/ui/folder_colors.dart
import 'package:flutter/material.dart';

class FolderColorHelper {
  static Color getColor(String folder) {
    final f = folder.toLowerCase();

    if (f.contains('classic') || f.contains('cláss'))
      return Colors.amber;
    if (f.contains('rock')) return Colors.redAccent;
    if (f.contains('pop')) return Colors.pinkAccent;
    if (f.contains('jazz')) return Colors.deepPurple;
    if (f.contains('electronic')) return Colors.cyan;

    return Colors.blueGrey;
  }
}
