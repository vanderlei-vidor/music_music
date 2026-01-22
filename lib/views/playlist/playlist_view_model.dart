import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:music_music/data/database_helper.dart';
import '../../models/music_entity.dart';

enum FavoriteOrder { recent, az }

class PlaylistViewModel extends ChangeNotifier {
  // 🎧 PLAYER
  final AudioPlayer _player = AudioPlayer();

  // 🗄️ DATABASE
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ❤️ FAVORITOS
  FavoriteOrder _favoriteOrder = FavoriteOrder.recent;
  FavoriteOrder get favoriteOrder => _favoriteOrder;

  List<MusicEntity> _favoriteMusics = [];
  List<MusicEntity> get favoriteMusics => _favoriteMusics;

  // 🕒 RECENTES
  List<MusicEntity> _recentMusics = [];
  List<MusicEntity> get recentMusics => _recentMusics;
  // contador
  List<MusicEntity> _mostPlayed = [];
  List<MusicEntity> get mostPlayed => _mostPlayed;

  // 🎵 STATE
  List<MusicEntity> _musics = [];
  MusicEntity? _currentMusic;

  bool _isShuffled = false;
  LoopMode _repeatMode = LoopMode.off;
  double _currentSpeed = 1.0;

  Timer? _sleepTimer;
  Duration? _sleepDuration;

  // =====================
  // GETTERS
  // =====================
  AudioPlayer get player => _player;
  List<MusicEntity> get musics => _musics;
  MusicEntity? get currentMusic => _currentMusic;
  bool get isShuffled => _isShuffled;
  LoopMode get repeatMode => _repeatMode;
  double get currentSpeed => _currentSpeed;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Stream<Duration> get positionStream => _player.positionStream;
  Duration? get sleepDuration => _sleepDuration;
  bool get hasSleepTimer => _sleepTimer?.isActive ?? false;

  // =====================
  // INIT
  // =====================
  PlaylistViewModel() {
    _initAudioSession();
    _listenToSequenceChanges();

    _player.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    loadAllMusics();
    loadRecentMusics();
    loadFavoriteMusics();
    loadMostPlayed();
  }

  // =====================
  // AUDIO SESSION
  // =====================
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  // =====================
  // DATABASE — MUSICS
  // =====================
  Future<void> loadAllMusics() async {
    _musics = await _dbHelper.getAllMusicsV2();
    notifyListeners();
  }

  void setMusics(List<MusicEntity> musics) {
    _musics = musics;
    _setAudioSource();
    notifyListeners();
  }

  // =====================
  // DATABASE — PLAYLISTS
  // =====================

  Future<void> createPlaylist(String name) async {
    await _dbHelper.createPlaylist(name);
    notifyListeners();
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _dbHelper.deletePlaylist(playlistId);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getPlaylists() {
    return _dbHelper.getPlaylists();
  }

  Future<List<Map<String, dynamic>>> getPlaylistsWithMusicCount() async {
    final playlists = await _dbHelper.getPlaylists();
    final List<Map<String, dynamic>> result = [];

    for (final playlist in playlists) {
      final playlistId = playlist['id'] as int;
      final count = await _dbHelper.getMusicCountForPlaylist(playlistId);

      result.add({
        'id': playlistId,
        'name': playlist['name'],
        'musicCount': count,
      });
    }

    return result;
  }

  // =====================
  // PLAYLIST ↔ MÚSICAS
  // =====================

  Future<List<MusicEntity>> getMusicsFromPlaylistV2(int playlistId) {
    return _dbHelper.getMusicsFromPlaylistV2(playlistId);
  }

  Future<void> addMusicToPlaylistV2(int playlistId, int musicId) async {
    await _dbHelper.addMusicToPlaylistV2(playlistId, musicId);
    notifyListeners();
  }

  Future<void> removeMusicFromPlaylist(int playlistId, int musicId) async {
    await _dbHelper.removeMusicFromPlaylistV2(playlistId, musicId);
    notifyListeners();
  }

  // =====================
  // AUDIO SOURCE
  // =====================
  Future<void> _setAudioSource({int? initialIndex}) async {
    if (_musics.isEmpty) return;

    final wasPlaying = _player.playing;
    final currentIndex = initialIndex ?? _player.currentIndex ?? 0;

    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: _musics.map((music) {
        return AudioSource.uri(
          Uri.parse(music.audioUrl),
          tag: MediaItem(
            id: music.id?.toString() ?? music.audioUrl,
            title: music.title,
            artist: music.artist,
            album: music.album,
            artUri: music.artworkUrl != null
                ? Uri.parse(music.artworkUrl!)
                : null,
          ),
        );
      }).toList(),
    );

    await _player.setAudioSource(
      playlist,
      initialIndex: currentIndex.clamp(0, _musics.length - 1),
      preload: false,
    );

    await _player.setShuffleModeEnabled(_isShuffled);

    if (wasPlaying) {
      await _player.play();
    }
  }

  // =====================
  // PLAYER LISTENER (RECENTES)
  // =====================
  void _listenToSequenceChanges() {
    _player.sequenceStateStream.listen((sequenceState) async {
      if (sequenceState == null || sequenceState.currentIndex == null) return;

      final index = sequenceState.currentIndex!;
      if (index < 0 || index >= _musics.length) return;

      final newMusic = _musics[index];

      if (_currentMusic?.id != newMusic.id) {
        _currentMusic = newMusic;

        // 🔥 AQUI É O LUGAR CERTO
        if (newMusic.id != null) {
          await _dbHelper.registerRecentPlay(newMusic.id!);
          await loadRecentMusics();
        }
        notifyListeners();
      }
    });
  }

  // =====================
  // CONTROLS (PREMIUM)
  // =====================

  // ▶️ PLAY / PAUSE
  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  void playPause() {
    if (_player.playing) {
      pause();
    } else {
      play();
    }
  }

  // 🎵 PLAY MÚSICA (contabiliza playCount + mantém fila correta)
  Future<void> playMusic(List<MusicEntity> queue, int index) async {
    if (queue.isEmpty) return;

    final isDifferentQueue =
        _musics.length != queue.length ||
        _musics.isEmpty ||
        _musics.first.id != queue.first.id;

    if (isDifferentQueue) {
      _musics = List.from(queue);
      await _setAudioSource(initialIndex: index);
    } else {
      await _player.seek(Duration.zero, index: index);
    }

    if (_isShuffled) {
      await _player.setShuffleModeEnabled(true);
      await _player.shuffle();
    }

    _currentMusic = _musics[index];
    await _player.play();

    notifyListeners();
  }

  // ⏭️ / ⏮️
  Future<void> nextMusic() async {
    await _player.seekToNext();
  }

  Future<void> previousMusic() async {
    await _player.seekToPrevious();
  }

  // ⏱️ SEEK
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> toggleShuffle() async {
    _isShuffled = !_isShuffled;

    await _player.setShuffleModeEnabled(_isShuffled);

    if (_isShuffled) {
      await _player.shuffle();
    } else {
      // volta para ordem original da fila atual
      await _setAudioSource(initialIndex: _player.currentIndex ?? 0);
    }

    notifyListeners();
  }

  void toggleRepeatMode() {
    if (_repeatMode == LoopMode.off) {
      _repeatMode = LoopMode.all;
    } else if (_repeatMode == LoopMode.all) {
      _repeatMode = LoopMode.one;
    } else {
      _repeatMode = LoopMode.off;
    }

    _player.setLoopMode(_repeatMode);
    notifyListeners();
  }

  void playAllFromPlaylist(List<MusicEntity> musics) {
    if (musics.isEmpty) return;

    final list = _isShuffled
        ? (List<MusicEntity>.from(musics)..shuffle())
        : musics;

    playMusic(list, 0);
  }

  // =====================
  // velocidade reprodução
  // =====================

  Future<void> setPlaybackSpeed(double speed) async {
    if (speed < 0.5 || speed > 2.0) return;

    _currentSpeed = speed;
    await _player.setSpeed(speed);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    if (volume < 0 || volume > 1) return;
    await _player.setVolume(volume);
    notifyListeners();
  }

  // =====================
  // FAVORITOS
  // =====================
  Future<void> loadFavoriteMusics() async {
    _favoriteMusics = await _dbHelper.getFavoriteMusics();

    if (_favoriteOrder == FavoriteOrder.az) {
      _favoriteMusics.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }

    notifyListeners();
  }

  Future<bool> toggleFavorite(MusicEntity music) async {
    final newValue = !music.isFavorite;

    await _dbHelper.toggleFavorite(music.audioUrl, newValue);

    final index = _musics.indexWhere((m) => m.id == music.id);
    if (index != -1) {
      _musics[index] = music.copyWith(isFavorite: newValue);
    }

    if (_currentMusic?.id == music.id) {
      _currentMusic = _musics[index];
    }

    await loadFavoriteMusics();
    notifyListeners();

    return newValue;
  }

  Future<void> toggleFavoriteOrder() async {
    _favoriteOrder = _favoriteOrder == FavoriteOrder.recent
        ? FavoriteOrder.az
        : FavoriteOrder.recent;

    await loadFavoriteMusics();
  }

  // =====================
  // RECENTES
  // =====================
  Future<void> loadRecentMusics() async {
    _recentMusics = await _dbHelper.getRecentMusics();
    notifyListeners();
  }

  Map<String, List<MusicEntity>> get recentGrouped {
    final grouped = {
      'Hoje': <MusicEntity>[],
      'Ontem': <MusicEntity>[],
      'Esta semana': <MusicEntity>[],
    };

    final now = DateTime.now();

    for (final music in _recentMusics) {
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

  Future<void> clearRecentHistory() async {
    await _dbHelper.clearRecentHistory();
    _recentMusics = [];
    notifyListeners();
  }

  // =====================
  // contador
  // =====================

  Future<void> loadMostPlayed() async {
    _mostPlayed = await _dbHelper.getMostPlayed(limit: 20);
    notifyListeners();
  }

  // =====================
  // SLEEP TIMER
  // =====================
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepDuration = duration;
    notifyListeners();

    _sleepTimer = Timer(duration, () {
      pause();
      _sleepTimer = null;
      _sleepDuration = null;
      notifyListeners();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepDuration = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> playSingleMusic(MusicEntity music) async {
    await playMusic([music], 0);
  }
}
