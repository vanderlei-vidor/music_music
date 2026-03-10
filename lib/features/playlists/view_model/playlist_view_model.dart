import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/controllers/library_controller.dart';
import 'package:music_music/features/playlists/controllers/playback_controller.dart';
import 'package:music_music/features/playlists/controllers/playback_queue_persistence.dart';
import 'package:music_music/features/playlists/data/playlist_library_repository.dart';
import 'package:music_music/features/playlists/models/favorite_order.dart';
import 'package:music_music/features/playlists/models/playback_issue.dart';
import 'package:music_music/features/playlists/models/sleep_timer_mode.dart';
import 'package:music_music/features/playlists/utils/playlist_genre_utils.dart';
import 'package:music_music/main.dart' as main_lib;

class PlaylistViewModel extends ChangeNotifier {
  final AudioHandler _handler;
  final PlaylistLibraryRepository _libraryRepository =
      PlaylistLibraryRepository();

  late final LibraryController _libraryController;
  late final PlaybackController _playbackController;

  PlaylistViewModel({required AudioHandler handler}) : _handler = handler {
    _libraryController = LibraryController(repository: _libraryRepository);
    _playbackController = PlaybackController(
      handler: _handler,
      queuePersistence: PlaybackQueuePersistence(
        repository: _libraryRepository,
      ),
      libraryController: _libraryController,
    );

    _libraryController.addListener(_forwardNotify);
    _playbackController.addListener(_forwardNotify);

    _playbackController
        .bindWidgetActionStream(main_lib.widgetActionController?.stream);

    loadAllMusics();
    loadRecentMusics();
    loadFavoriteMusics();
    loadMostPlayed();
    loadPlaylistsWithMusicCount();
  }

  void _forwardNotify() {
    notifyListeners();
  }

  AudioHandler get handler => _playbackController.handler;

  List<MusicEntity> get libraryMusics => _libraryController.libraryMusics;
  List<MusicEntity> get queueMusics => _playbackController.queueMusics;
  MusicEntity? get currentMusic => _playbackController.currentMusic;

  bool get isShuffled => _playbackController.isShuffled;
  LoopMode get repeatMode => _playbackController.repeatMode;
  double get currentSpeed => _playbackController.currentSpeed;

  bool get gaplessEnabled => _playbackController.gaplessEnabled;
  bool get crossfadeEnabled => _playbackController.crossfadeEnabled;
  int get crossfadeSeconds => _playbackController.crossfadeSeconds;
  Duration get crossfadeDuration => _playbackController.crossfadeDuration;
  bool get isCrossfadeActive => _playbackController.isCrossfadeActive;
  bool get isLoadingConfig => _playbackController.isLoadingConfig;

  bool get isPlaying => _playbackController.isPlaying;
  int get currentIndex => _playbackController.currentIndex;
  Duration get currentPosition => _playbackController.currentPosition;
  double get currentVolume => _playbackController.currentVolume;

  Stream<Duration> get positionStream => _playbackController.positionStream;
  Stream<bool> get playingStream => _playbackController.playingStream;
  Stream<double> get speedStream => _playbackController.speedStream;

  FavoriteOrder get favoriteOrder => _libraryController.favoriteOrder;
  List<MusicEntity> get favoriteMusics => _libraryController.favoriteMusics;

  List<MusicEntity> get recentMusics => _libraryController.recentMusics;
  List<MusicEntity> get mostPlayed => _libraryController.mostPlayed;

  List<Map<String, dynamic>> get playlistsWithMusicCount =>
      _libraryController.playlistsWithMusicCount;

  bool get isLoadingPlaylistsWithCount =>
      _libraryController.isLoadingPlaylistsWithCount;
  bool get isReprocessingGenres => _libraryController.isReprocessingGenres;

  Duration? get sleepDuration => _playbackController.sleepDuration;
  bool get hasSleepTimer => _playbackController.hasSleepTimer;
  DateTime? get sleepEndTime => _playbackController.sleepEndTime;
  SleepTimerMode get sleepMode => _playbackController.sleepMode;
  Duration? get sleepRemaining => _playbackController.sleepRemaining;

  Color get currentDominantColor => _playbackController.currentDominantColor;
  String? get currentGenre => _playbackController.currentGenre;
  Color? get currentGenreColor => _playbackController.currentGenreColor;
  List<PlaybackIssue> get playbackIssues => _playbackController.playbackIssues;

  void clearPlaybackIssues() => _playbackController.clearPlaybackIssues();

  Future<void> loadAllMusics() async {
    final allMusics = await _libraryController.loadAllMusics();
    await _playbackController.applyLibraryMusics(allMusics);
  }

  Future<void> setQueueMusics(List<MusicEntity> musics) async {
    await _playbackController.setQueueMusics(musics);
  }

  Future<void> createPlaylist(String name) async {
    await _libraryController.createPlaylist(name);
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _libraryController.deletePlaylist(playlistId);
  }

  Future<List<Map<String, dynamic>>> getPlaylists() {
    return _libraryController.getPlaylists();
  }

  Future<List<Map<String, dynamic>>> getPlaylistsWithMusicCount() async {
    return _libraryController.getPlaylistsWithMusicCount();
  }

  Future<void> loadPlaylistsWithMusicCount({bool force = false}) async {
    await _libraryController.loadPlaylistsWithMusicCount(force: force);
  }

  Future<List<MusicEntity>> getMusicsFromPlaylistV2(int playlistId) {
    return _libraryController.getMusicsFromPlaylistV2(playlistId);
  }

  Future<void> addMusicToPlaylistV2(int playlistId, int musicId) async {
    await _libraryController.addMusicToPlaylistV2(playlistId, musicId);
  }

  Future<void> removeMusicFromPlaylist(int playlistId, int musicId) async {
    await _libraryController.removeMusicFromPlaylist(playlistId, musicId);
  }

  Future<void> play() async => _playbackController.play();
  Future<void> pause() async => _playbackController.pause();
  void playPause() => _playbackController.playPause();

  Future<void> playMusic(List<MusicEntity> queue, int index) async {
    await _playbackController.playMusic(queue, index);
  }

  Future<void> playSingleMusic(MusicEntity music) async {
    await playMusic([music], 0);
  }

  Future<void> nextMusic() async => _playbackController.nextMusic();
  Future<void> previousMusic() async => _playbackController.previousMusic();
  Future<void> seek(Duration position) async => _playbackController.seek(position);

  Future<void> toggleShuffle() async => _playbackController.toggleShuffle();
  Future<void> toggleRepeatMode() async => _playbackController.toggleRepeatMode();

  Future<void> playAllFromPlaylist(List<MusicEntity> musics) async {
    await _playbackController.playAllFromPlaylist(musics);
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    await _playbackController.reorderQueue(oldIndex, newIndex);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _playbackController.setPlaybackSpeed(speed);
  }

  Future<void> setVolume(double volume) async {
    await _playbackController.setVolume(volume);
  }

  Future<bool> toggleFavorite(MusicEntity music) async {
    return _playbackController.toggleFavorite(music);
  }

  Future<void> toggleFavoriteOrder() async {
    await _libraryController.toggleFavoriteOrder();
  }

  Future<void> loadFavoriteMusics() async {
    await _libraryController.loadFavoriteMusics();
  }

  Future<void> loadRecentMusics() async {
    await _libraryController.loadRecentMusics();
  }

  Future<void> clearRecentHistory() async {
    await _libraryController.clearRecentHistory();
  }

  Future<void> loadMostPlayed() async {
    await _libraryController.loadMostPlayed();
  }

  Future<int> runGenreReprocess() async {
    final updated = await _libraryController.runGenreReprocess();
    await _playbackController.applyLibraryMusics(
      _libraryController.libraryMusics,
    );
    return updated;
  }

  void setSleepTimer(Duration duration) {
    _playbackController.setSleepTimer(duration);
  }

  void cancelSleepTimer() {
    _playbackController.cancelSleepTimer();
  }

  void setSleepTimerEndOfSong() {
    _playbackController.setSleepTimerEndOfSong();
  }

  void setSleepTimerEndOfPlaylist() {
    _playbackController.setSleepTimerEndOfPlaylist();
  }

  void setDominantColor(Color color) {
    _playbackController.setDominantColor(color);
  }

  Future<void> setGaplessEnabled(bool enabled) async {
    await _playbackController.setGaplessEnabled(enabled);
  }

  Future<void> setCrossfadeEnabled(bool enabled) async {
    await _playbackController.setCrossfadeEnabled(enabled);
  }

  Future<void> setCrossfadeSeconds(int seconds) async {
    await _playbackController.setCrossfadeSeconds(seconds);
  }

  Map<String, List<MusicEntity>> get folders =>
      PlaylistGenreUtils.buildFolders(_libraryController.libraryMusics);

  Map<String, List<MusicEntity>> get genres =>
      PlaylistGenreUtils.buildGenres(_libraryController.libraryMusics);

  Map<String, List<MusicEntity>> normalizeGenreGroups(
    Map<String, List<MusicEntity>> original,
  ) {
    return PlaylistGenreUtils.normalizeGenreGroups(original);
  }

  Map<String, List<MusicEntity>> get recentGrouped {
    final grouped = {
      'Hoje': <MusicEntity>[],
      'Ontem': <MusicEntity>[],
      'Esta semana': <MusicEntity>[],
    };

    final now = DateTime.now();

    for (final music in _libraryController.recentMusics) {
      if (music.lastPlayedAt == null) continue;

      final played = DateTime.fromMillisecondsSinceEpoch(music.lastPlayedAt!);
      final diff = now.difference(played).inDays;

      if (diff == 0) {
        grouped['Hoje']!.add(music);
      } else if (diff == 1) {
        grouped['Ontem']!.add(music);
      } else if (diff <= 7) {
        grouped['Esta semana']!.add(music);
      }
    }

    return grouped;
  }

  @override
  void dispose() {
    _libraryController.removeListener(_forwardNotify);
    _playbackController.removeListener(_forwardNotify);
    _playbackController.dispose();
    _libraryController.dispose();
    super.dispose();
  }
}
