import 'package:shared_preferences/shared_preferences.dart';

class FeaturedPrefsSnapshot {
  final String date;
  final List<String> audioUrls;
  final int featuredIndex;

  const FeaturedPrefsSnapshot({
    required this.date,
    required this.audioUrls,
    required this.featuredIndex,
  });
}

class FeaturedPrefs {
  static const String _dateKey = 'featured_day_date';
  static const String _queueKey = 'featured_day_queue_urls';
  static const String _indexKey = 'featured_day_index';

  static Future<FeaturedPrefsSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final date = prefs.getString(_dateKey);
    final queue = prefs.getStringList(_queueKey);
    final index = prefs.getInt(_indexKey) ?? 0;

    if (date == null || queue == null || queue.isEmpty) return null;
    return FeaturedPrefsSnapshot(
      date: date,
      audioUrls: queue,
      featuredIndex: index,
    );
  }

  static Future<void> save({
    required String date,
    required List<String> audioUrls,
    int featuredIndex = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, date);
    await prefs.setStringList(_queueKey, audioUrls);
    await prefs.setInt(_indexKey, featuredIndex);
  }

  static Future<void> saveIndex({
    required String date,
    required int featuredIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, date);
    await prefs.setInt(_indexKey, featuredIndex);
  }
}
