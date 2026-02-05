import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import 'package:music_music/core/music/music_scanner.dart';
import 'package:music_music/data/models/music_entity.dart';

class DesktopMusicScanner implements MusicScanner {
  @override
  Future<List<MusicEntity>> scan() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return [];

    final dir = Directory(result);

    final files = dir
        .listSync(recursive: true)
        .where(
          (f) =>
              f.path.toLowerCase().endsWith('.mp3') ||
              f.path.toLowerCase().endsWith('.wav') ||
              f.path.toLowerCase().endsWith('.m4a'),
        )
        .toList();

    return files.map((file) {
      return MusicEntity(
        id: null,
        title: path.basenameWithoutExtension(file.path),
        artist: 'Desconhecido',
        audioUrl: file.path,
        folderPath: path.dirname(file.path),
      );
    }).toList();
  }
}

