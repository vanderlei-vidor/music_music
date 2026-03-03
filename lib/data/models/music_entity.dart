import 'dart:io';

import 'package:on_audio_query/on_audio_query.dart';
import 'dart:convert';

class MusicEntity {
  final int? id;
  final int? sourceId;
  final String title;
  final String artist;
  final String audioUrl;
  final String? artworkUrl;
  final int? duration;
  final String? album;
  final String? genre;
  final String? mediaType;
  final bool isFavorite;
  final String? folderPath;

  /// 🕒 timestamp em millis
  final int? lastPlayedAt;
  final int playCount;

  MusicEntity({
    required this.id,
    this.sourceId,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.artworkUrl,
    this.duration,
    this.album,
    this.genre,
    this.mediaType,
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

    final rawGenre = song.genre?.trim();
    final inferredGenre = _inferGenreFromFolderPath(folderPath);
    final heuristicGenre = _inferGenreFromText(
      title: song.title,
      artist: song.artist,
      album: song.album,
    );
    final effectiveGenre = (rawGenre != null && rawGenre.isNotEmpty)
        ? rawGenre
        : (inferredGenre ?? heuristicGenre);

    return MusicEntity(
      id: song.id,
      sourceId: song.id,
      title: song.title,
      artist: song.artist ?? 'Artista desconhecido',
      album: song.album,
      genre: effectiveGenre,
      mediaType: null,
      duration: song.duration,
      audioUrl: song.uri ?? '',
      artworkUrl: null,
      lastPlayedAt: null,
      playCount: 0,
      folderPath: folderPath,
    );
  }

  static String? _inferGenreFromFolderPath(String? folderPath) {
    if (folderPath == null || folderPath.trim().isEmpty) return null;
    final normalized = folderPath.replaceAll('\\', '/');
    final parts = normalized.split('/').where((e) => e.trim().isNotEmpty);
    if (parts.isEmpty) return null;
    final last = parts.last.trim();
    if (last.isEmpty) return null;
    return last;
  }

  static String? _inferGenreFromText({
    required String title,
    String? artist,
    String? album,
  }) {
    final text = '${title.toLowerCase()} ${artist?.toLowerCase() ?? ''} '
        '${album?.toLowerCase() ?? ''}';

    if (_containsAny(text, const ['mozart', 'bach', 'beethoven', 'chopin'])) {
      return 'Classica';
    }
    if (_containsAny(text, const ['samba', 'pagode', 'axé', 'axe'])) {
      return 'Samba/Pagode';
    }
    if (_containsAny(text, const ['forro', 'piseiro', 'sertanejo', 'arrocha'])) {
      return 'Sertanejo/Forro';
    }
    if (_containsAny(text, const ['gospel', 'worship', 'louvor'])) {
      return 'Gospel';
    }
    if (_containsAny(text, const ['rock', 'metal', 'punk'])) {
      return 'Rock';
    }
    if (_containsAny(text, const ['funk', 'trap', 'hip hop', 'rap'])) {
      return 'Hip Hop/Funk';
    }
    if (_containsAny(text, const ['jazz', 'blues', 'bossa'])) {
      return 'Jazz/Blues';
    }
    return null;
  }

  static bool _containsAny(String value, List<String> tokens) {
    for (final token in tokens) {
      if (value.contains(token)) return true;
    }
    return false;
  }

  // 🔥 VINDO DO BANCO
  factory MusicEntity.fromMap(Map<String, dynamic> map) {
    return MusicEntity(
      id: map['id'],
      sourceId: map['sourceId'],
      title: map['title'],
      artist: map['artist'],
      audioUrl: map['audioUrl'],
      artworkUrl: map['artworkUrl'],
      duration: map['duration'],
      album: map['album'],
      genre: map['genre'],
      mediaType: map['mediaType'],
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      lastPlayedAt: map['lastPlayedAt'],
      playCount: map['playCount'] ?? 0,
      folderPath: map['folderPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceId': sourceId,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'artworkUrl': artworkUrl,
      'duration': duration,
      'album': album,
      'genre': genre,
      'mediaType': mediaType,
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
    int? sourceId,
    String? genre,
    String? mediaType,
    String? folderPath,
  }) {
    return MusicEntity(
      id: id,
      sourceId: sourceId ?? this.sourceId,
      title: title,
      artist: artist,
      audioUrl: audioUrl,
      artworkUrl: artworkUrl,
      duration: duration,
      album: album,
      genre: genre ?? this.genre,
      mediaType: mediaType ?? this.mediaType,
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
      'sourceId': sourceId,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'artworkUrl': artworkUrl,
      'duration': duration,
      'album': album,
      'genre': genre,
      'mediaType': mediaType,
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
      sourceId: map['sourceId'],
      title: map['title'],
      artist: map['artist'],
      audioUrl: map['audioUrl'],
      artworkUrl: map['artworkUrl'],
      duration: map['duration'],
      album: map['album'],
      genre: map['genre'],
      mediaType: map['mediaType'],
      isFavorite: map['isFavorite'] ?? false,
      lastPlayedAt: map['lastPlayedAt'],
      playCount: map['playCount'] ?? 0,
      folderPath: map['folderPath'],
    );
  }
}
