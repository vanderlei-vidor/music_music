import 'dart:io';

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
  final String? genre;
  final bool isFavorite;
  final String? folderPath;

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
    this.genre,
    this.isFavorite = false,
    this.lastPlayedAt,
    this.playCount = 0,
    this.folderPath,
  });

  factory MusicEntity.fromSongModel(SongModel song) {
  String? folderPath;

  try {
    final uri = Uri.parse(song.uri ?? '');
    final file = File(uri.toFilePath());

    folderPath = file.parent.path;
  } catch (e) {
    folderPath = null;
  }

    return MusicEntity(
      id: song.id,
      title: song.title,
      artist: song.artist ?? 'Artista desconhecido',
      album: song.album,
      genre: song.genre,
      duration: song.duration,
      audioUrl: song.uri ?? '',
      artworkUrl: null,
      lastPlayedAt: null,
      playCount: 0,
      folderPath: folderPath,
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
      genre: map['genre'],
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      lastPlayedAt: map['lastPlayedAt'],
      playCount: map['playCount'] ?? 0,
      folderPath: map['folderPath'],
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
      'genre': genre,
      'isFavorite': isFavorite ? 1 : 0,
      'lastPlayedAt': lastPlayedAt,
      'playCount': playCount,
      'folderPath': folderPath,
    };
  }

  MusicEntity copyWith({
    bool? isFavorite,
    int? lastPlayedAt,
    int? playCount,
    String? genre,
    String? folderPath,
  }) {
    return MusicEntity(
      id: id,
      title: title,
      artist: artist,
      audioUrl: audioUrl,
      artworkUrl: artworkUrl,
      duration: duration,
      album: album,
      genre: genre ?? this.genre,
      isFavorite: isFavorite ?? this.isFavorite,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      playCount: playCount ?? this.playCount,
      folderPath: folderPath ?? this.folderPath,
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
      'genre': genre,
      'isFavorite': isFavorite,
      'lastPlayedAt': lastPlayedAt,
      'playCount': playCount,
      'folderPath': folderPath,
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
      genre: map['genre'],
      isFavorite: map['isFavorite'] ?? false,
      lastPlayedAt: map['lastPlayedAt'],
      playCount: map['playCount'] ?? 0,
      folderPath: map['folderPath'],
    );
  }
}
