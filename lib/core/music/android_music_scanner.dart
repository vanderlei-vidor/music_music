import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import '../../models/music_entity.dart';
import 'music_scanner.dart';

class AndroidMusicScanner implements MusicScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  Future<List<MusicEntity>> scan() async {
    final hasPermission = await _audioQuery.permissionsStatus();
    if (!hasPermission) {
      final granted = await _audioQuery.permissionsRequest();
      if (!granted) return [];
    }

    final songs = await _audioQuery.querySongs(
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return songs
    .where((s) => s.data != null && (s.duration ?? 0) > 10000)
    .map((s) {
      final fullPath = s.data!;
      final parts = fullPath.split('/');

      final folderName =
          parts.length > 1 ? parts[parts.length - 2] : 'Desconhecido';

      print('🚨 ANDROID SCANNER ATIVO');
      print('🔥🔥🔥 ANDROID SCANNER REAL SENDO USADO 🔥🔥🔥');
      print('🎧 ${s.title} | pasta: $folderName');

      return MusicEntity(
        id: null,
        title: s.title,
        artist: s.artist ?? 'Desconhecido',
        album: s.album,
        genre: s.genre,
        audioUrl: fullPath,
        artworkUrl: null,
        duration: s.duration,
        isFavorite: false,
        folderPath: folderName, // ✅ AGORA FUNCIONA
      );
    })
    .toList();

  }
}
