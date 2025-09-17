// core/services/music_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../models/music_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dart_tags/dart_tags.dart'; // ✅ Importe dart_tags
import '../../data/database_helper.dart'; // ✅ Importe o DatabaseHelper

class MusicService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final DatabaseHelper _dbHelper = DatabaseHelper(); // ✅ Instância do DB Helper

  Future<bool> requestPermission() async {
    // ... seu código de permissão (sem alterações)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return true;
    }
    if (Platform.isAndroid) {
      if (await Permission.audio.isGranted) return true;
      var audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;
      var storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }

  Future<List<Music>> getSongs() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      debugPrint('Permissão negada para acessar músicas');
      return [];
    }

    List<Music> allMusics = [];

    if (Platform.isAndroid || Platform.isIOS) {
      // ✅ Lógica para mobile (Android/iOS)
      try {
        final songs = await _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        for (final song in songs) {
          final music = Music.fromSongModel(song);
          allMusics.add(music);
          await _dbHelper.insertMusic(music); // ✅ Salva no banco de dados
        }
      } catch (e) {
        debugPrint('Erro ao carregar músicas no mobile: $e');
      }
    } else {
      // ✅ Lógica para desktop (corrigida)
      try {
        final Directory? musicDir = await _getMusicDirectory();
        if (musicDir != null && await musicDir.exists()) {
          await for (final FileSystemEntity file in musicDir.list(recursive: true)) {
            if (file is File && file.path.toLowerCase().endsWith('.mp3')) {
              try {
                final tagProcessor = TagProcessor();
                final tags = await tagProcessor.getTagsFromByteArray(file.readAsBytes());

                String title = p.basenameWithoutExtension(file.path);
                String artist = 'Unknown';
                
                final tag = tags.firstWhere(
                  (t) => t.tags.isNotEmpty,
                  orElse: () => Tag(),
                );
                
                if (tag.tags.isNotEmpty) {
                  title = tag.tags['title'] ?? title;
                  artist = tag.tags['artist'] ?? artist;
                }

                final music = Music(
                  id: file.path.hashCode,
                  title: title,
                  artist: artist,
                  uri: file.path,
                  data: file.path,
                  duration: 0,
                  albumId: 0,
                  album: '',
                  albumArtUri: '',
                );
                
                allMusics.add(music);
                await _dbHelper.insertMusic(music); 
              } catch (e) {
                // ✅ ADICIONADO: Bloco try-catch para ignorar arquivos corrompidos
                debugPrint('Erro ao processar arquivo de música, ignorando: ${file.path}');
                debugPrint('Detalhes do erro: $e');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Erro ao carregar músicas no desktop: $e');
      }
    }
    
    return allMusics;
  }

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
    return null;
  }
}