import 'dart:html';

import '../models/music_entity.dart';

class WebMusicStore {
  static final _storage = window.localStorage;

  static Future<void> insert(MusicEntity music) async {
    _storage[music.audioUrl] = music.toJson();
  }

  static Future<List<MusicEntity>> getAll() async {
    return _storage.values
        .map((e) => MusicEntity.fromJson(e))
        .toList();
  }
}
