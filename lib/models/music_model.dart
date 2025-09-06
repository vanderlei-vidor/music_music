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
  final String? data;
  final int? duration;
  final int? albumId;
  final String? album;
  final String? albumArtUri;
  bool isFavorite;

  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    required this.data,
    this.duration,
    this.albumId,
    this.album,
    this.albumArtUri,
    this.isFavorite = false,
  });

  factory Music.fromSongModel(SongModel song) {
    return Music(
      id: song.id,
      title: song.title,
      artist: song.artist ?? 'Artista desconhecido',
      uri: song.uri!,
      data: song.data,
      duration: song.duration,
      albumId: song.albumId,
      album: song.album,
      albumArtUri: null, 
      
    );
  }

  // Método para converter para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'uri': uri,
      'data': data,
      'duration': duration,
      'albumId': albumId,
      'album': album,
      'albumArtUri': albumArtUri,
      'isFavorite': isFavorite ? 1 : 0, // Converta o bool para int
    };
  }

  // Factory constructor para criar Music a partir de um Map
  factory Music.fromMap(Map<String, dynamic> map) {
    return Music(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      uri: map['uri'],
      data: map['data'],
      duration: map['duration'],
      albumId: map['albumId'],
      album: map['album'],
      albumArtUri: map['albumArtUri'],
      isFavorite: map['isFavorite'] == 1,
    );
  }

  
}
