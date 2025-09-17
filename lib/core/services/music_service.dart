// core/services/music_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../models/music_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
 final files = musicDir.listSync(recursive: true, followLinks: false)
 .where((item) => item.path.toLowerCase().endsWith('.mp3') || item.path.toLowerCase().endsWith('.m4a'));
 
 for (final FileSystemEntity file in files) {
 if (file is File) {
 try {
 final metadata = await MetadataGod.readMetadata(file.path);

final music = Music(
 id: file.path.hashCode,
 title: metadata.title ?? p.basenameWithoutExtension(file.path),
 artist: metadata.artist ?? 'Unknown',
 uri: file.path,
 data: file.path,
 duration: metadata.durationMs,
 albumId: null, // metadata_god não tem essa propriedade
 album: metadata.album ?? 'Unknown',
albumArtUri: '',
 );
 allMusics.add(music);
 await _dbHelper.insertMusic(music);
 } catch (e) {
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