import 'dart:html' as html;
import 'package:music_music/data/models/music_entity.dart';

class WebMusicUploader {
  // Use dynamic aqui na entrada para a HomeScreen não reclamar no Windows
  static Future<List<MusicEntity>> upload(dynamic files) async {
    // Aqui dentro você faz o cast com segurança
    final List<html.File> webFiles = List<html.File>.from(files as List);
    
    final List<MusicEntity> result = [];
    for (final file in webFiles) {
      final url = html.Url.createObjectUrl(file);
      result.add(MusicEntity(
        title: file.name,
        audioUrl: url,
        artist: 'Importado',
        isFavorite: false, id: null,
      ));
    }
    return result;
  }
}
