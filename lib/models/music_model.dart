import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Music {
  final int id;
  final String title;
  final String artist;
  final String uri;
  final int? duration;
  final int? albumId;
  final String? album;
  final String? albumArtUri;

  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    this.duration,
    this.albumId,
    this.album,
    this.albumArtUri,
  });

  factory Music.fromSongModel(SongModel song) {
    return Music(
      id: song.id,
      title: song.title,
      artist: song.artist ?? 'Artista desconhecido',
      uri: song.uri!,
      duration: song.duration,
      albumId: song.albumId,
      album: song.album,
      albumArtUri: null, // Linha corrigida para remover o erro
    );
  }

  // Método para converter para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'uri': uri,
      'duration': duration,
      'albumId': albumId,
      'album': album,
      'albumArtUri': albumArtUri,
    };
  }

  // Factory constructor para criar Music a partir de um Map
  factory Music.fromMap(Map<String, dynamic> map) {
    return Music(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      uri: map['uri'],
      duration: map['duration'],
      albumId: map['albumId'],
      album: map['album'],
      albumArtUri: map['albumArtUri'],
    );
  }
}
