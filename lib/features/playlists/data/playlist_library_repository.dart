import 'package:music_music/data/local/database_helper.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/data/playback_queue_repository.dart';

class PlaylistLibraryRepository implements PlaybackQueueRepository {
  final DatabaseHelper _db;

  PlaylistLibraryRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  Future<List<MusicEntity>> getAllMusics() => _db.getAllMusicsV2();

  Future<void> clearPlaybackQueue() => _db.clearPlaybackQueue();

  Future<void> createPlaylist(String name) => _db.createPlaylist(name);

  Future<void> deletePlaylist(int playlistId) => _db.deletePlaylist(playlistId);

  Future<List<Map<String, dynamic>>> getPlaylists() => _db.getPlaylists();

  Future<List<Map<String, dynamic>>> getPlaylistsWithMusicCount() =>
      _db.getPlaylistsWithMusicCount();

  Future<List<MusicEntity>> getMusicsFromPlaylistV2(int playlistId) =>
      _db.getMusicsFromPlaylistV2(playlistId);

  Future<void> addMusicToPlaylistV2(int playlistId, int musicId) =>
      _db.addMusicToPlaylistV2(playlistId, musicId);

  Future<void> removeMusicFromPlaylistV2(int playlistId, int musicId) =>
      _db.removeMusicFromPlaylistV2(playlistId, musicId);

  Future<void> registerRecentPlay(int musicId) => _db.registerRecentPlay(musicId);

  Future<List<MusicEntity>> getFavoriteMusics() => _db.getFavoriteMusics();

  Future<void> toggleFavorite(String audioUrl, bool isFavorite) =>
      _db.toggleFavorite(audioUrl, isFavorite);

  Future<List<MusicEntity>> getRecentMusics() => _db.getRecentMusics();

  Future<void> clearRecentHistory() => _db.clearRecentHistory();

  Future<List<MusicEntity>> getMostPlayed({int limit = 20}) =>
      _db.getMostPlayed(limit: limit);

  Future<int> reprocessGenresBatch() => _db.reprocessGenresBatch();

  Future<Map<String, dynamic>?> loadPlaybackQueue() => _db.loadPlaybackQueue();

  Future<void> savePlaybackQueue({
    required List<String> audioUrls,
    required int currentIndex,
    required int positionMs,
  }) =>
      _db.savePlaybackQueue(
        audioUrls: audioUrls,
        currentIndex: currentIndex,
        positionMs: positionMs,
      );
}
