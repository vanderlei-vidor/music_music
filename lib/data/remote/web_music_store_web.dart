import 'package:music_music/data/models/music_entity.dart';
import 'package:web/web.dart' as web;

class WebMusicStore {
  static final web.Storage _storage = web.window.localStorage;

  static Future<void> insert(MusicEntity music) async {
    _storage.setItem(music.audioUrl, music.toJson());
  }

  static Future<List<MusicEntity>> getAll() async {
    final result = <MusicEntity>[];
    for (var i = 0; i < _storage.length; i++) {
      final key = _storage.key(i);
      if (key == null) continue;
      final json = _storage.getItem(key);
      if (json == null || json.isEmpty) continue;
      result.add(MusicEntity.fromJson(json));
    }
    return result;
  }
}
