import 'package:music_music/data/models/music_entity.dart';

abstract class MusicScanner {
  Future<List<MusicEntity>> scan();
}

