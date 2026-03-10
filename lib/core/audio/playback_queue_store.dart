import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_music/data/models/music_entity.dart';

class PlaybackQueueSnapshot {
  final List<MediaItem> items;
  final int currentIndex;
  final int positionMs;

  const PlaybackQueueSnapshot({
    required this.items,
    required this.currentIndex,
    required this.positionMs,
  });
}

class PlaybackQueueStore {
  static const String _queueKey = 'playback_queue_snapshot_v2';

  static Future<void> saveSnapshot({
    required List<MusicEntity> queue,
    required int currentIndex,
    required int positionMs,
  }) async {
    if (queue.isEmpty) return;
    final payload = {
      'currentIndex': currentIndex,
      'positionMs': positionMs,
      'items': queue.map(_entityToMap).toList(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, jsonEncode(payload));
  }

  static Future<PlaybackQueueSnapshot?> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final itemsRaw = decoded['items'];
    if (itemsRaw is! List) return null;
    final items = <MediaItem>[];
    for (final item in itemsRaw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final mediaItem = _mapToMediaItem(map);
      if (mediaItem != null) {
        items.add(mediaItem);
      }
    }
    if (items.isEmpty) return null;
    final currentIndex = _toInt(decoded['currentIndex']) ?? 0;
    final positionMs = _toInt(decoded['positionMs']) ?? 0;
    return PlaybackQueueSnapshot(
      items: items,
      currentIndex: currentIndex.clamp(0, items.length - 1),
      positionMs: positionMs.clamp(0, 1 << 30),
    );
  }

  static Map<String, dynamic> _entityToMap(MusicEntity m) {
    return {
      'id': m.id,
      'sourceId': m.sourceId,
      'title': m.title,
      'artist': m.artist,
      'album': m.album,
      'artworkUrl': m.artworkUrl,
      'audioUrl': m.audioUrl,
      'duration': m.duration,
    };
  }

  static MediaItem? _mapToMediaItem(Map<String, dynamic> map) {
    final audioUrl = map['audioUrl']?.toString();
    final title = map['title']?.toString();
    if (audioUrl == null || audioUrl.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    final artist = map['artist']?.toString() ?? 'Desconhecido';
    final album = map['album']?.toString();
    final artworkUrl = map['artworkUrl']?.toString();
    final durationMs = _toInt(map['duration']);
    return MediaItem(
      id: map['id']?.toString() ?? audioUrl,
      title: title,
      artist: artist,
      album: album,
      artUri: (artworkUrl != null && artworkUrl.isNotEmpty)
          ? Uri.tryParse(artworkUrl)
          : null,
      duration: durationMs != null ? Duration(milliseconds: durationMs) : null,
      extras: {
        'audioUrl': audioUrl,
        'sourceId': map['sourceId'],
        'artworkUrl': artworkUrl,
      },
    );
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
