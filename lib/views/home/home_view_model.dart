// lib/views/home/home_view_model.dart
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../models/music_model.dart';

class HomeViewModel extends ChangeNotifier {
  // Adicione a propriedade para a instância de OnAudioQuery
  final OnAudioQuery _audioQuery;

  // Crie um construtor que aceita OnAudioQuery como parâmetro
  HomeViewModel(this._audioQuery);

  final List<Music> _musics = [];
  bool _isLoading = true;

  List<Music> get musics => _musics;
  bool get isLoading => _isLoading;

  Future<void> loadMusics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<SongModel> songs = await _audioQuery.querySongs(
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        sortType: null,
        ignoreCase: true,
      );

      _musics.clear();
      for (var song in songs) {
        if (song.isMusic!) {
          _musics.add(
            Music(
              id: song.id,
              title: song.title,
              artist: song.artist ?? "Desconhecido",
              uri: song.uri!,
              data: song.data,
              albumId: song.albumId,
              duration: song.duration,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar músicas: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para buscar músicas por título
  List<Music> searchMusics(String query) {
    if (query.isEmpty) {
      return _musics;
    }
    return _musics
        .where((music) =>
            music.title.toLowerCase().contains(query.toLowerCase()) ||
            music.artist.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
