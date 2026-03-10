import 'package:flutter/foundation.dart';
import 'package:music_music/core/utils/genre_normalizer.dart';
import 'package:music_music/data/models/music_entity.dart';

class PlaylistGenreUtils {
  static Map<String, List<MusicEntity>> buildFolders(List<MusicEntity> musics) {
    final Map<String, List<MusicEntity>> result = {};

    for (final music in musics) {
      if (kDebugMode) {
        debugPrint('folder item: ${music.title} | ${music.folderPath}');
      }
      final folder = music.folderPath ?? 'Desconhecido';
      result.putIfAbsent(folder, () => []).add(music);
    }

    return result;
  }

  static Map<String, List<MusicEntity>> buildGenres(List<MusicEntity> musics) {
    final Map<String, List<MusicEntity>> temp = {};

    for (final music in musics) {
      final genre = GenreNormalizer.normalize(music.genre);
      temp.putIfAbsent(genre, () => []).add(music);
    }

    return normalizeGenreGroups(temp);
  }

  static Map<String, List<MusicEntity>> normalizeGenreGroups(
    Map<String, List<MusicEntity>> original,
  ) {
    final Map<String, List<MusicEntity>> result = {};
    final List<MusicEntity> others = [];

    original.forEach((genre, musics) {
      if (musics.length < 3) {
        others.addAll(musics);
      } else {
        result[genre] = musics;
      }
    });

    if (others.isNotEmpty) {
      result['Outros'] = others;
    }

    return result;
  }

  static String? resolveCurrentGenre(MusicEntity music) {
    final rawGenre = music.genre?.trim();
    if (rawGenre != null && rawGenre.isNotEmpty) return rawGenre;

    final folder = music.folderPath?.trim();
    if (folder != null && folder.isNotEmpty) {
      final normalizedPath = folder.replaceAll('\\', '/');
      final segments = normalizedPath
          .split('/')
          .where((segment) => segment.trim().isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        return segments.last.trim();
      }
    }

    return inferGenreFromText(music);
  }

  static String? inferGenreFromText(MusicEntity music) {
    final text = _normalizeForGenreGuess(
      '${music.title} ${music.artist} ${music.album ?? ''}',
    );

    if (_containsAnyToken(text, const ['mozart', 'bach', 'beethoven', 'chopin'])) {
      return 'Classica';
    }
    if (_containsAnyToken(text, const ['samba', 'pagode', 'axe'])) {
      return 'Samba/Pagode';
    }
    if (_containsAnyToken(text, const ['forro', 'piseiro', 'sertanejo', 'arrocha'])) {
      return 'Sertanejo/Forro';
    }
    if (_containsAnyToken(text, const ['gospel', 'worship', 'louvor'])) {
      return 'Gospel';
    }
    if (_containsAnyToken(text, const ['rock', 'metal', 'punk'])) {
      return 'Rock';
    }
    if (_containsAnyToken(text, const ['funk', 'trap', 'hip hop', 'rap'])) {
      return 'Hip Hop/Funk';
    }
    if (_containsAnyToken(text, const ['jazz', 'blues', 'bossa'])) {
      return 'Jazz/Blues';
    }
    return null;
  }

  static String _normalizeForGenreGuess(String value) {
    final lowercase = value.toLowerCase();
    final sb = StringBuffer();
    const map = {
      '\u00e1': 'a',
      '\u00e0': 'a',
      '\u00e2': 'a',
      '\u00e3': 'a',
      '\u00e4': 'a',
      '\u00e9': 'e',
      '\u00e8': 'e',
      '\u00ea': 'e',
      '\u00eb': 'e',
      '\u00ed': 'i',
      '\u00ec': 'i',
      '\u00ee': 'i',
      '\u00ef': 'i',
      '\u00f3': 'o',
      '\u00f2': 'o',
      '\u00f4': 'o',
      '\u00f5': 'o',
      '\u00f6': 'o',
      '\u00fa': 'u',
      '\u00f9': 'u',
      '\u00fb': 'u',
      '\u00fc': 'u',
      '\u00e7': 'c',
    };
    for (final rune in lowercase.runes) {
      final ch = String.fromCharCode(rune);
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }

  static bool _containsAnyToken(String value, List<String> tokens) {
    for (final token in tokens) {
      if (value.contains(token)) return true;
    }
    return false;
  }
}
