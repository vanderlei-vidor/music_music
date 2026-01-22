import 'package:on_audio_query/on_audio_query.dart';

import 'package:music_music/core/music/music_scanner.dart';
import '../../models/music_entity.dart';

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
        .where((s) => s.uri != null && (s.duration ?? 0) > 10000)
        .map(
          (s) => MusicEntity(
            id: null, // ⚠️ sempre null aqui
            title: s.title,
            artist: s.artist ?? 'Desconhecido',
            album: s.album,
            audioUrl: s.uri!,
            artworkUrl: null,
            duration: s.duration,
            isFavorite: false,
          ),
        )
        .toList();
  }
}
