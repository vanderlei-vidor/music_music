// core/services/music_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../models/music_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // Importe para juntar caminhos

class MusicService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Pede permissão de acordo com a versão do Android.
  Future<bool> requestPermission() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return true;
    }
    // ... restante do seu código para Android/iOS
    if (Platform.isAndroid) {
      if (await Permission.audio.isGranted) return true;
      var audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;
      var storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true; // iOS
  }

  /// Carrega músicas do dispositivo.
  Future<List<Music>> getSongs() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      debugPrint('Permissão negada para acessar músicas');
      return [];
    }

    if (Platform.isAndroid || Platform.isIOS) {
      // ... sua lógica para mobile (sem alterações)
      try {
        final songs = await _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        return songs.map((song) => Music.fromSongModel(song)).toList();
      } catch (e) {
        debugPrint('Erro ao carregar músicas no mobile: $e');
        return [];
      }
    } else {
      // ✅ Lógica para desktop
      try {
        final Directory? musicDir = await _getMusicDirectory();
        if (musicDir == null || !await musicDir.exists()) {
          debugPrint('Diretório de músicas não encontrado.');
          return [];
        }

        final List<FileSystemEntity> files = musicDir.listSync(recursive: true);
        final List<Music> desktopSongs = [];
        for (final FileSystemEntity file in files) {
          if (file is File && file.path.endsWith('.mp3')) {
            debugPrint('Música encontrada: ${file.path}');
            desktopSongs.add(Music(
              id: file.hashCode,
              title: p.basenameWithoutExtension(file.path),
              artist: 'Unknown',
              uri: file.path,
              data: file.path,
              duration: 0,
              albumId: 0,
              album: 'Unknown',
              albumArtUri: '',
            ));
          }
        }
        return desktopSongs;
      } catch (e) {
        debugPrint('Erro ao carregar músicas no desktop: $e');
        return [];
      }
    }
  }

  /// ✅ Função corrigida para encontrar o diretório de Músicas.
  Future<Directory?> _getMusicDirectory() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return Directory(p.join(userProfile, 'Music'));
      }
    } else if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return Directory(p.join(home, 'Music'));
      }
    }
    // Retorna nulo se o diretório não for encontrado
    return null;
  }
}