// lib/views/home/home_view_model.dart
import 'package:flutter/material.dart';
import '../../models/music_model.dart';
import '../../core/services/music_service.dart'; // ✅ Importe seu MusicService

class HomeViewModel extends ChangeNotifier {
  // ✅ Remova a dependência de OnAudioQuery no construtor.
  // ✅ Instancie o MusicService diretamente.
  final MusicService _musicService = MusicService();

  final List<Music> _musics = [];
  bool _isLoading = true;

  // Construtor sem argumentos.
  HomeViewModel() {
    loadMusics(); // ✅ Inicie o carregamento de músicas automaticamente.
  }

  List<Music> get musics => _musics;
  bool get isLoading => _isLoading;

  Future<void> loadMusics() async {
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ Agora, ele usa o MusicService para buscar as músicas.
      // A lógica de plataforma está toda dentro do MusicService.
      final List<Music> songs = await _musicService.getSongs();

      _musics.clear();
      _musics.addAll(songs);
      
    } catch (e) {
      debugPrint("Erro ao carregar músicas: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para buscar músicas por título (sem alterações necessárias).
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