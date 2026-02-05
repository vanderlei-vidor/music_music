// lib/core/services/music_service.dart

import 'package:on_audio_query/on_audio_query.dart';

import 'package:music_music/data/local/database_helper.dart';
import 'package:music_music/data/models/music_entity.dart';

class MusicService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  bool _isImporting = false;

  /// 🔥 Importa músicas do DISPOSITIVO e salva no banco
  //Future<List<MusicEntity>> importMusics() async {
  //  if (_isImporting) return [];
 //   _isImporting = true;

 //   try {
      // 🔐 Permissão obrigatória
 //     final permission = await _audioQuery.permissionsStatus();
 //     if (!permission) {
 //       await _audioQuery.permissionsRequest();
 //     }

      // 🎧 BUSCA TODAS AS MÚSICAS DO DISPOSITIVO
 //     final songs = await _audioQuery.querySongs(
 //       uriType: UriType.EXTERNAL,
 //       ignoreCase: true,
 //     );

  //    final List<MusicEntity> imported = [];

   //   for (final song in songs) {
   //     if (song.uri == null) continue;

   //     final music = MusicEntity.fromSongModel(song);

   //     await _dbHelper.insertMusicV2(music);
   //     imported.add(music);
  //    }

 //     return imported;
 //   } finally {
 //     _isImporting = false;
 //   }
//  }

  /// 🔁 Carrega músicas já salvas no banco
  Future<List<MusicEntity>> getAllMusics() async {
    return await _dbHelper.getAllMusicsV2();
  }
}

