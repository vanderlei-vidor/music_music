// models/music_model.dart
import 'package:on_audio_query/on_audio_query.dart';

class Music {
  final int id;
  final String title;
  final String artist;
  final String uri;
  final int? albumId;
  final String? album; // <-- novo campo
  final int? duration;
  final String? albumArtUri;

  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    this.albumId,
    this.album, // <-- incluído
    this.duration,
    this.albumArtUri,
  });

  factory Music.fromSongModel(SongModel song, {String? albumArtUri}) {
    return Music(
      id: song.id,
      title: song.title,
      artist: song.artist ?? 'Artista Desconhecido',
      uri: song.uri ?? '',
      albumId: song.albumId,
      album: song.album,
      duration: song.duration,
      albumArtUri:
          albumArtUri ??
          (song.albumId != null
              ? "content://media/external/audio/albumart/${song.albumId}"
              : null),
    );
  }
}
