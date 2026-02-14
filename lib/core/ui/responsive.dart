import 'package:flutter/material.dart';

enum SizeClass { compact, medium, expanded }

class Responsive {
  static SizeClass of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return SizeClass.compact;
    if (width < 1024) return SizeClass.medium;
    return SizeClass.expanded;
  }

  static T value<T>(
    BuildContext context, {
    required T compact,
    required T medium,
    required T expanded,
  }) {
    switch (of(context)) {
      case SizeClass.compact:
        return compact;
      case SizeClass.medium:
        return medium;
      case SizeClass.expanded:
        return expanded;
    }
  }

  static int columnsForGrid(BuildContext context) {
    return value(context, compact: 2, medium: 3, expanded: 5);
  }
}
