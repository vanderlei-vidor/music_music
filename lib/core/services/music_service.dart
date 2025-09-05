// core/services/music_service.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../models/music_model.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Pede permissão de acordo com a versão do Android
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33) usa permissões de mídia separadas
      if (await Permission.audio.isGranted) return true;

      var audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;

      // Android 12 ou menor usa "storage"
      if (await Permission.storage.isGranted) return true;

      var storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }

    // iOS não precisa para OnAudioQuery
    return true;
  }

  /// Carrega músicas do dispositivo
  Future<List<Music>> getSongs() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      debugPrint('Permissão negada para acessar músicas');
      return [];
    }

    try {
      final songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      return songs.map((song) => Music.fromSongModel(song)).toList();
    } catch (e) {
      debugPrint('Erro ao carregar músicas: $e');
      return [];
    }
  }
}

