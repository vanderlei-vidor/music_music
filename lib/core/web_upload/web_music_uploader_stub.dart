import '../../models/music_entity.dart';

// O Windows lê esta classe. Ela PRECISA ter o mesmo nome da classe da Web.
class WebMusicUploader {
  static Future<List<MusicEntity>> upload(dynamic files) async {
    // No Windows, retornamos uma lista vazia porque essa função não existe aqui
    return [];
  }
}