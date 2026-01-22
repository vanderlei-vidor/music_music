

import 'package:flutter/material.dart';



TextSpan highlight(String text, String query, TextStyle style) {
  if (query.isEmpty) return TextSpan(text: text, style: style);

  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();

  final start = lowerText.indexOf(lowerQuery);
  if (start < 0) return TextSpan(text: text, style: style);

  return TextSpan(
    children: [
      TextSpan(text: text.substring(0, start), style: style),
      TextSpan(
        text: text.substring(start, start + query.length),
        style: style.copyWith(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
      TextSpan(
        text: text.substring(start + query.length),
        style: style,
      ),
    ],
  );
}
