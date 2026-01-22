import '../../models/music_entity.dart';

abstract class MusicScanner {
  Future<List<MusicEntity>> scan();
}
