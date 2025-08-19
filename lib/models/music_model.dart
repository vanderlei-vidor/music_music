// models/music_model.dart
import 'package:on_audio_query/on_audio_query.dart';

class Music {
  final int id;
  final String title;
  final String artist;
  final String uri;
  final int? albumId;
  final int? duration;

  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    this.albumId,
    this.duration,
  });

  factory Music.fromSongModel(SongModel song) {
    return Music(
      id: song.id,
      title: song.title,
      artist: song.artist ?? 'Artista Desconhecido',
      uri: song.uri ?? '',
      albumId: song.albumId,
      duration: song.duration,
    );
  }
}