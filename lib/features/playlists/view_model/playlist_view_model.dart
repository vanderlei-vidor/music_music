import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_music/core/ui/genre_colors.dart';
import 'package:music_music/core/utils/genre_normalizer.dart';

import 'package:music_music/data/local/database_helper.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:music_music/data/models/music_entity.dart';

enum FavoriteOrder { recent, az }

enum SleepTimerMode { off, duration, endOfSong, endOfPlaylist }

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
  Timer? _sleepTick;
  Duration? _sleepDuration;
  DateTime? _sleepEndTime;
  SleepTimerMode _sleepMode = SleepTimerMode.off;
  int _lastEndOfSongSecond = -1;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  Duration? _sleepPausedRemaining;
  bool _restoringQueue = false;
  bool _isPersistingQueue = false;
  DateTime? _lastQueuePersistAt;
  Duration _lastPersistedPosition = Duration.zero;

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
  DateTime? get sleepEndTime => _sleepEndTime;
  SleepTimerMode get sleepMode => _sleepMode;
  Duration? get sleepRemaining {
    if (_sleepEndTime == null) return null;
    final remaining = _sleepEndTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Color _currentDominantColor = Colors.blueGrey.shade600;

  Color get currentDominantColor => _currentDominantColor;

  String? _currentGenre;
  Color? _currentGenreColor;

  String? get currentGenre => _currentGenre;
  Color? get currentGenreColor => _currentGenreColor;

  // =====================
  // INIT
  // =====================
  PlaylistViewModel() {
    _initAudioSession();
    _listenToSequenceChanges();

    _player.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();

      if (!playing) {
        _pauseSleepTimer();
        _persistPlaybackQueue(force: true);
      } else {
        _resumeSleepTimerIfNeeded();
      }
    });

    _player.currentIndexStream.listen((_) {
      _persistPlaybackQueue();
    });

    _positionSub = _player.positionStream.listen((position) {
      _persistPlaybackQueue();

      if (_sleepMode == SleepTimerMode.endOfSong) {
        if (position.inSeconds != _lastEndOfSongSecond) {
          _lastEndOfSongSecond = position.inSeconds;
          _syncEndOfSongTimer(position: position);

          
        }
      } else if (_sleepMode == SleepTimerMode.endOfPlaylist) {
        _syncEndOfPlaylistTimer(position: position);
      }
    });

    _playerStateSub = _player.playerStateStream.listen((state) {
      if (_sleepMode == SleepTimerMode.endOfPlaylist &&
          state.processingState == ProcessingState.completed) {
        _clearSleepTimer();
      }
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
    final allMusics = await _dbHelper.getAllMusicsV2();
    _musics = allMusics;

    if (_musics.isNotEmpty) {
      final restored = await _restorePlaybackQueue(allMusics);
      if (!restored) {
        await _setAudioSource(initialIndex: 0);
      }
    } else {
      await _dbHelper.clearPlaybackQueue();
    }

    notifyListeners();
    _persistPlaybackQueue();
  }

  void setMusics(List<MusicEntity> musics) {
    _musics = musics;
    _setAudioSource();
    _persistPlaybackQueue();
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

    final children = <AudioSource>[];

    for (final music in _musics) {
      final uri = Uri.parse(music.audioUrl);

      children.add(
        AudioSource.uri(
          uri,
          tag: MediaItem(
            id: music.id?.toString() ?? music.audioUrl,
            title: music.title,
            artist: music.artist,
            album: music.album,
            artUri: music.artworkUrl != null
                ? Uri.parse(music.artworkUrl!)
                : null,
          ),
        ),
      );
    }

    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: children,
    );

    await _player.setAudioSource(
      playlist,
      initialIndex: currentIndex.clamp(0, children.length - 1),
    );

    await _player.setShuffleModeEnabled(_isShuffled);

    if (wasPlaying) {
      await _player.play();
    }
    _persistPlaybackQueue();
  }

  // =====================
  // PLAYER LISTENER (RECENTES)
  // =====================
  void _listenToSequenceChanges() {
    _player.sequenceStateStream.listen((sequenceState) async {
      if (sequenceState == null) return;

      final index = sequenceState.currentIndex;
      if (index < 0 || index >= _musics.length) return;

      final newMusic = _musics[index];

      if (_currentMusic?.id != newMusic.id) {
        _currentMusic = newMusic;
        // 🎼 gênero atual
        _currentGenre = newMusic.genre;

        // 🎨 cor do gênero
        if (newMusic.genre != null && newMusic.genre!.isNotEmpty) {
          _currentGenreColor = GenreColorHelper.getColor(newMusic.genre!);
        } else {
          _currentGenreColor = null;
        }

        await _updateDominantColor(newMusic);

        if (_sleepMode == SleepTimerMode.endOfSong) {
          _syncEndOfSongTimer();
        } else if (_sleepMode == SleepTimerMode.endOfPlaylist) {
          _syncEndOfPlaylistTimer();
        }

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

    final isDifferentQueue = !listEquals(
      _musics.map((e) => e.id).toList(),
      queue.map((e) => e.id).toList(),
    );

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
    print('▶️ play chamado');
    await _player.play();

    _persistPlaybackQueue();
    notifyListeners();
  }

  // ⏭️ / ⏮️
  Future<void> nextMusic() async {
    await _player.seekToNext();
    _persistPlaybackQueue();
  }

  Future<void> previousMusic() async {
    await _player.seekToPrevious();
    _persistPlaybackQueue();
  }

  // ⏱️ SEEK
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _persistPlaybackQueue();
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

  Future<void> playAllFromPlaylist(List<MusicEntity> musics) async {
    if (musics.isEmpty) return;

    final list = _isShuffled
        ? (List<MusicEntity>.from(musics)..shuffle())
        : musics;

    await playMusic(list, 0);
    _persistPlaybackQueue();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (_musics.isEmpty) return;
    if (oldIndex < 0 || oldIndex >= _musics.length) return;
    if (newIndex < 0 || newIndex > _musics.length) return;

    final currentId = _currentMusic?.id;
    final targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    final moved = _musics.removeAt(oldIndex);
    _musics.insert(targetIndex, moved);

    var nextCurrentIndex = 0;
    if (currentId != null) {
      final idx = _musics.indexWhere((m) => m.id == currentId);
      nextCurrentIndex = idx == -1 ? 0 : idx;
    } else {
      nextCurrentIndex = targetIndex.clamp(0, _musics.length - 1);
    }

    await _setAudioSource(initialIndex: nextCurrentIndex);
    notifyListeners();
    _persistPlaybackQueue();
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
    _sleepMode = SleepTimerMode.duration;
    _sleepDuration = duration;
    _startSleepCountdown(duration, force: true);
  }

  void cancelSleepTimer() {
    _clearSleepTimer();
  }

  void setSleepTimerEndOfSong() {
    _sleepMode = SleepTimerMode.endOfSong;
    _sleepDuration = null;
    _syncEndOfSongTimer();
  }

  void setSleepTimerEndOfPlaylist() {
    _sleepMode = SleepTimerMode.endOfPlaylist;
    _sleepDuration = null;
    _syncEndOfPlaylistTimer();
  }

  @override
  void dispose() {
    unawaited(_persistPlaybackQueueOnDispose());
    _sleepTimer?.cancel();
    _sleepTick?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _startSleepCountdown(Duration remaining, {bool force = true}) {
    if (!_player.playing) {
      _sleepPausedRemaining = remaining;
      notifyListeners();
      return;
    }

    final newEndTime = DateTime.now().add(remaining);
    if (!force && _sleepEndTime != null && _sleepTimer?.isActive == true) {
      final delta = _sleepEndTime!.difference(newEndTime).abs();
      if (delta < const Duration(seconds: 2)) {
        return;
      }
    }

    _sleepTimer?.cancel();
    _sleepTick?.cancel();

    _sleepEndTime = newEndTime;
    notifyListeners();

    _sleepTimer = Timer(remaining, () {
      pause();
      _clearSleepTimer();
    });

    _sleepTick = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _clearSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTick?.cancel();
    _sleepTimer = null;
    _sleepTick = null;
    _sleepDuration = null;
    _sleepEndTime = null;
    _sleepMode = SleepTimerMode.off;
    _sleepPausedRemaining = null;
    notifyListeners();
  }

  Future<bool> _restorePlaybackQueue(List<MusicEntity> allMusics) async {
    final saved = await _dbHelper.loadPlaybackQueue();
    if (saved == null) return false;

    final savedUrls = (saved['audioUrls'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    if (savedUrls.isEmpty) return false;

    final byUrl = <String, MusicEntity>{};
    for (final music in allMusics) {
      byUrl[music.audioUrl] = music;
    }

    final restoredQueue = <MusicEntity>[];
    for (final url in savedUrls) {
      final music = byUrl[url];
      if (music != null) restoredQueue.add(music);
    }
    if (restoredQueue.isEmpty) return false;

    _restoringQueue = true;
    _musics = restoredQueue;

    final rawIndex = saved['currentIndex'] as int? ?? 0;
    final currentIndex = rawIndex.clamp(0, _musics.length - 1);
    await _setAudioSource(initialIndex: currentIndex);

    final positionMs = saved['positionMs'] as int? ?? 0;
    if (positionMs > 0) {
      await _player.seek(
        Duration(milliseconds: positionMs),
        index: currentIndex,
      );
    }
    _restoringQueue = false;
    _persistPlaybackQueue();
    return true;
  }

  Future<void> _persistPlaybackQueue({bool force = false}) async {
    if (_restoringQueue) return;
    if (_musics.isEmpty) {
      await _dbHelper.clearPlaybackQueue();
      return;
    }
    if (_isPersistingQueue) return;

    final now = DateTime.now();
    final sinceLastPersist = _lastQueuePersistAt == null
        ? null
        : now.difference(_lastQueuePersistAt!);
    final movedMs = (_player.position - _lastPersistedPosition).inMilliseconds.abs();
    final shouldThrottle =
        !force &&
        sinceLastPersist != null &&
        sinceLastPersist < const Duration(seconds: 5) &&
        movedMs < 3000;

    if (shouldThrottle) return;

    final currentIndex = (_player.currentIndex ?? 0).clamp(0, _musics.length - 1);
    final positionMs = _player.position.inMilliseconds;

    _isPersistingQueue = true;
    try {
      await _dbHelper.savePlaybackQueue(
        audioUrls: _musics.map((m) => m.audioUrl).toList(),
        currentIndex: currentIndex,
        positionMs: positionMs,
      );
      _lastQueuePersistAt = now;
      _lastPersistedPosition = _player.position;
    } finally {
      _isPersistingQueue = false;
    }
  }

  Future<void> _persistPlaybackQueueOnDispose() async {
    if (_restoringQueue) return;

    if (_musics.isEmpty) {
      await _dbHelper.clearPlaybackQueue();
      return;
    }

    final currentIndex = (_player.currentIndex ?? 0).clamp(0, _musics.length - 1);
    final positionMs = _player.position.inMilliseconds;
    final urls = _musics.map((m) => m.audioUrl).toList();

    await _dbHelper.savePlaybackQueue(
      audioUrls: urls,
      currentIndex: currentIndex,
      positionMs: positionMs,
    );
  }

  void _pauseSleepTimer() {
    if (_sleepTimer == null) return;
    if (_sleepEndTime == null) return;

    final remaining = _sleepEndTime!.difference(DateTime.now());
    _sleepPausedRemaining =
        remaining.isNegative ? Duration.zero : remaining;
    _sleepTimer?.cancel();
    _sleepTick?.cancel();
    _sleepTimer = null;
    _sleepTick = null;
    notifyListeners();
  }

  void _resumeSleepTimerIfNeeded() {
    if (_sleepMode == SleepTimerMode.off) return;

    if (_sleepMode == SleepTimerMode.duration) {
      if (_sleepPausedRemaining != null) {
        _startSleepCountdown(_sleepPausedRemaining!, force: true);
        _sleepPausedRemaining = null;
      }
      return;
    }

    if (_sleepMode == SleepTimerMode.endOfSong) {
      _syncEndOfSongTimer();
      return;
    }

    if (_sleepMode == SleepTimerMode.endOfPlaylist) {
      _syncEndOfPlaylistTimer();
    }
  }

  void _syncEndOfSongTimer({Duration? position}) {
    if (_currentMusic == null) return;
    final durationMs = _currentMusic?.duration ?? 0;
    if (durationMs <= 0) return;

    final pos = position ?? _player.position;
    final remainingMs = (durationMs - pos.inMilliseconds).clamp(0, durationMs);
    _startSleepCountdown(Duration(milliseconds: remainingMs), force: false);
  }

  void _syncEndOfPlaylistTimer({Duration? position}) {
    if (_musics.isEmpty) return;
    final index = _player.currentIndex ?? 0;
    if (index < 0 || index >= _musics.length) return;

    final pos = position ?? _player.position;
    final currentMs = _musics[index].duration ?? 0;
    if (currentMs <= 0) return;

    var remainingMs = (currentMs - pos.inMilliseconds).clamp(0, currentMs);

    for (var i = index + 1; i < _musics.length; i++) {
      remainingMs += _musics[i].duration ?? 0;
    }

    _startSleepCountdown(Duration(milliseconds: remainingMs), force: false);
  }

  Future<void> playSingleMusic(MusicEntity music) async {
    await playMusic([music], 0);
  }

  void setDominantColor(Color color) {
    _currentDominantColor = color;
    notifyListeners();
  }

  Future<void> _updateDominantColor(MusicEntity music) async {
    final artwork = music.artworkUrl;

    // 🎨 cor fallback elegante (nunca preto)
    final fallbackColor = Colors.blueGrey.shade600;

    if (artwork == null || artwork.isEmpty) {
      _currentDominantColor = fallbackColor;

      debugPrint('🎨 sem artwork → fallback | música: ${music.title}');

      notifyListeners();
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(artwork),
        maximumColorCount: 10,
      );

      _currentDominantColor =
          palette.vibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.dominantColor?.color ??
          fallbackColor;

      debugPrint(
        '🎨 nova cor: $_currentDominantColor | música: ${music.title}',
      );
    } catch (e) {
      debugPrint('🎨 erro palette: $e');

      _currentDominantColor = fallbackColor;
    }

    notifyListeners();
  }

  // =====================
  // pastas
  // =====================

  Map<String, List<MusicEntity>> get folders {
    final Map<String, List<MusicEntity>> result = {};

    for (final m in _musics) {
      print('🎧 ${m.title} | pasta: ${m.folderPath}');
      final folder = m.folderPath ?? 'Desconhecido';

      result.putIfAbsent(folder, () => []).add(m);
    }

    return result;
  }

  // =====================
  // gêneros
  // =====================

  Map<String, List<MusicEntity>> get genres {
    final Map<String, List<MusicEntity>> temp = {};

    // 1️⃣ Normaliza os gêneros
    for (final m in _musics) {
      final genre = GenreNormalizer.normalize(m.genre);
      temp.putIfAbsent(genre, () => []).add(m);
    }

    // 2️⃣ Agrupa gêneros pequenos em "Outros"
    final Map<String, List<MusicEntity>> result = {};
    final List<MusicEntity> others = [];

    temp.forEach((genre, musics) {
      if (musics.length < 3) {
        others.addAll(musics);
      } else {
        result[genre] = musics;
      }
    });

    if (others.isNotEmpty) {
      result['Outros'] = others;
    }

    return result;
  }

  Map<String, List<MusicEntity>> normalizeGenreGroups(
    Map<String, List<MusicEntity>> original,
  ) {
    final Map<String, List<MusicEntity>> result = {};
    final List<MusicEntity> others = [];

    original.forEach((genre, musics) {
      if (musics.length < 3) {
        others.addAll(musics);
      } else {
        result[genre] = musics;
      }
    });

    if (others.isNotEmpty) {
      result['Outros'] = others;
    }

    return result;
  }
}


