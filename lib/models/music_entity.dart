import 'package:on_audio_query/on_audio_query.dart';
import 'dart:convert';

class MusicEntity {
  final int? id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? artworkUrl;
  final int? duration;
  final String? album;
  final bool isFavorite;

  /// 🕒 timestamp em millis
  final int? lastPlayedAt;
  final int playCount;

  MusicEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.artworkUrl,
    this.duration,
    this.album,
    this.isFavorite = false,
    this.lastPlayedAt,
    this.playCount = 0,
  });

  // 🔥 VINDO DO SISTEMA (SongModel)
  factory MusicEntity.fromSongModel(SongModel song) {
    return MusicEntity(
      id: song.id,
      title: song.title,
      artist: song.artist ?? 'Artista desconhecido',
      album: song.album,
      duration: song.duration,
      audioUrl: song.uri!,
      artworkUrl: null,
      lastPlayedAt: null, // ainda não tocada
      playCount: 0,
      
    );
  }

  // 🔥 VINDO DO BANCO
  factory MusicEntity.fromMap(Map<String, dynamic> map) {
  return MusicEntity(
    id: map['id'],
    title: map['title'],
    artist: map['artist'],
    audioUrl: map['audioUrl'],
    artworkUrl: map['artworkUrl'],
    duration: map['duration'],
    album: map['album'],
    isFavorite: (map['isFavorite'] ?? 0) == 1,
    lastPlayedAt: map['playedAt'] ?? map['lastPlayedAt'],
    playCount: map['playCount'] ?? 0,
  );
}

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'artworkUrl': artworkUrl,
      'duration': duration,
      'album': album,
      'isFavorite': isFavorite ? 1 : 0,
      'lastPlayedAt': lastPlayedAt,
      'playCount': playCount,
    };
  }

  MusicEntity copyWith({bool? isFavorite, int? lastPlayedAt,int? playCount,}) {
    return MusicEntity(
      id: id,
      title: title,
      artist: artist,
      audioUrl: audioUrl,
      artworkUrl: artworkUrl,
      duration: duration,
      album: album,
      isFavorite: isFavorite ?? this.isFavorite,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      playCount: playCount ?? this.playCount,
    );
  }

  // =========================
  // JSON (WEB STORAGE)
  // =========================

  String toJson() {
    return jsonEncode({
      'id': id,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'artworkUrl': artworkUrl,
      'duration': duration,
      'album': album,
      'isFavorite': isFavorite,
      'lastPlayedAt': lastPlayedAt,
      'playCount': playCount,
    });
  }

  factory MusicEntity.fromJson(String source) {
    final map = jsonDecode(source);

    return MusicEntity(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      audioUrl: map['audioUrl'],
      artworkUrl: map['artworkUrl'],
      duration: map['duration'],
      album: map['album'],
      isFavorite: map['isFavorite'] ?? false,
      lastPlayedAt: map['lastPlayedAt'],
      playCount: map['playCount'] ?? 0,
    );
  }
}
