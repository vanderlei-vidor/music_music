import 'package:music_music/models/music_entity.dart';

enum SearchType { music, artist, album }

class SearchResult {
  final SearchType type;
  final String title;
  final MusicEntity? music;

  SearchResult({
    required this.type,
    required this.title,
    this.music,
  });
}
