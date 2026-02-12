import 'package:web/web.dart' as web;
import 'package:music_music/data/models/music_entity.dart';

class WebMusicUploader {
  static Future<List<MusicEntity>> upload(dynamic files) async {
    final iterable = files is Iterable ? files : const <dynamic>[];
    final result = <MusicEntity>[];

    for (final raw in iterable) {
      final file = raw as web.File;
      final url = web.URL.createObjectURL(file);
      result.add(
        MusicEntity(
          id: null,
          title: file.name,
          audioUrl: url,
          artist: 'Importado',
          isFavorite: false,
        ),
      );
    }

    return result;
  }
}
