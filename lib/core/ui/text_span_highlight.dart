import 'package:flutter/material.dart';

final _highlightCache = <String, TextSpan>{};
const _highlightCacheLimit = 500;

TextSpan highlight(String text, String query, TextStyle style) {
  final key = '${style.hashCode}|$query|$text';
  final cached = _highlightCache.remove(key);
  if (cached != null) {
    _highlightCache[key] = cached;
    return cached;
  }

  if (query.isEmpty) return TextSpan(text: text, style: style);

  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();

  final start = lowerText.indexOf(lowerQuery);
  if (start < 0) return TextSpan(text: text, style: style);

  final result = TextSpan(
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
  _highlightCache[key] = result;
  if (_highlightCache.length > _highlightCacheLimit) {
    _highlightCache.remove(_highlightCache.keys.first);
  }
  return result;
}
