


import 'package:music_music/core/music/music_scanner.dart';
import 'package:music_music/models/music_entity.dart';
import 'package:path_provider/path_provider.dart';

class IOSMusicScanner implements MusicScanner {
  @override
  Future<List<MusicEntity>> scan() async {
    final dir = await getApplicationDocumentsDirectory();

    final files = dir
        .listSync()
        .where((f) =>
            f.path.endsWith('.mp3') ||
            f.path.endsWith('.m4a') ||
            f.path.endsWith('.wav'))
        .toList();

    return files.map((f) {
      return MusicEntity(
        id: null,
        title: f.uri.pathSegments.last,
        artist: 'Importado',
        audioUrl: f.path,
      );
    }).toList();
  }
}
