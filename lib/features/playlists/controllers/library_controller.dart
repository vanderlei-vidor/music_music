import 'package:flutter/foundation.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/data/playlist_library_repository.dart';
import 'package:music_music/features/playlists/models/favorite_order.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({required PlaylistLibraryRepository repository})
      : _repository = repository;

  final PlaylistLibraryRepository _repository;

  FavoriteOrder _favoriteOrder = FavoriteOrder.recent;
  FavoriteOrder get favoriteOrder => _favoriteOrder;

  List<MusicEntity> _libraryMusics = [];
  List<MusicEntity> get libraryMusics => _libraryMusics;

  List<MusicEntity> _favoriteMusics = [];
  List<MusicEntity> get favoriteMusics => _favoriteMusics;

  List<MusicEntity> _recentMusics = [];
  List<MusicEntity> get recentMusics => _recentMusics;

  List<MusicEntity> _mostPlayed = [];
  List<MusicEntity> get mostPlayed => _mostPlayed;

  List<Map<String, dynamic>> _playlistsWithMusicCount = [];
  List<Map<String, dynamic>> get playlistsWithMusicCount =>
      List.unmodifiable(_playlistsWithMusicCount);

  bool _isLoadingPlaylistsWithCount = false;
  bool get isLoadingPlaylistsWithCount => _isLoadingPlaylistsWithCount;

  bool _isReprocessingGenres = false;
  bool get isReprocessingGenres => _isReprocessingGenres;

  Future<List<MusicEntity>> loadAllMusics() async {
    _libraryMusics = await _repository.getAllMusics();
    notifyListeners();
    return _libraryMusics;
  }

  Future<void> loadFavoriteMusics() async {
    _favoriteMusics = await _repository.getFavoriteMusics();

    if (_favoriteOrder == FavoriteOrder.az) {
      _favoriteMusics.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    notifyListeners();
  }

  Future<void> toggleFavoriteOrder() async {
    _favoriteOrder = _favoriteOrder == FavoriteOrder.recent
        ? FavoriteOrder.az
        : FavoriteOrder.recent;
    await loadFavoriteMusics();
  }

  Future<void> applyFavoriteChange(MusicEntity music, bool newValue) async {
    await _repository.toggleFavorite(music.audioUrl, newValue);

    final libraryIndex =
        _libraryMusics.indexWhere((m) => m.audioUrl == music.audioUrl);
    if (libraryIndex != -1) {
      _libraryMusics[libraryIndex] = music.copyWith(isFavorite: newValue);
    }

    await loadFavoriteMusics();
  }

  Future<void> loadRecentMusics() async {
    _recentMusics = await _repository.getRecentMusics();
    notifyListeners();
  }

  Future<void> registerRecentPlay(int musicId) async {
    await _repository.registerRecentPlay(musicId);
    await loadRecentMusics();
  }

  Future<void> clearRecentHistory() async {
    await _repository.clearRecentHistory();
    _recentMusics = [];
    notifyListeners();
  }

  Future<void> loadMostPlayed() async {
    _mostPlayed = await _repository.getMostPlayed(limit: 20);
    notifyListeners();
  }

  Future<int> runGenreReprocess() async {
    if (_isReprocessingGenres) return 0;
    _isReprocessingGenres = true;
    notifyListeners();
    try {
      final updated = await _repository.reprocessGenresBatch();
      await loadAllMusics();
      return updated;
    } finally {
      _isReprocessingGenres = false;
      notifyListeners();
    }
  }

  Future<void> createPlaylist(String name) async {
    await _repository.createPlaylist(name);
    await loadPlaylistsWithMusicCount(force: true);
    notifyListeners();
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _repository.deletePlaylist(playlistId);
    await loadPlaylistsWithMusicCount(force: true);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getPlaylists() {
    return _repository.getPlaylists();
  }

  Future<List<Map<String, dynamic>>> getPlaylistsWithMusicCount() async {
    await loadPlaylistsWithMusicCount();
    return playlistsWithMusicCount;
  }

  Future<void> loadPlaylistsWithMusicCount({bool force = false}) async {
    if (_isLoadingPlaylistsWithCount) return;
    if (!force && _playlistsWithMusicCount.isNotEmpty) return;

    _isLoadingPlaylistsWithCount = true;
    notifyListeners();

    try {
      _playlistsWithMusicCount =
          await _repository.getPlaylistsWithMusicCount();
    } finally {
      _isLoadingPlaylistsWithCount = false;
      notifyListeners();
    }
  }

  Future<List<MusicEntity>> getMusicsFromPlaylistV2(int playlistId) {
    return _repository.getMusicsFromPlaylistV2(playlistId);
  }

  Future<void> addMusicToPlaylistV2(int playlistId, int musicId) async {
    await _repository.addMusicToPlaylistV2(playlistId, musicId);
    await loadPlaylistsWithMusicCount(force: true);
    notifyListeners();
  }

  Future<void> removeMusicFromPlaylist(int playlistId, int musicId) async {
    await _repository.removeMusicFromPlaylistV2(playlistId, musicId);
    await loadPlaylistsWithMusicCount(force: true);
    notifyListeners();
  }
}
