import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_music/core/observability/app_logger.dart';
import 'package:music_music/core/ui/genre_colors.dart';
import 'package:music_music/core/utils/genre_normalizer.dart';
import 'package:music_music/core/preferences/playback_preferences.dart';

import 'package:music_music/data/local/database_helper.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:music_music/data/models/music_entity.dart';

enum FavoriteOrder { recent, az }

enum SleepTimerMode { off, duration, endOfSong, endOfPlaylist }

class PlaylistViewModel extends ChangeNotifier {
  // 🎧 PLAYER
  final AudioPlayer _player;

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
  List<Map<String, dynamic>> _playlistsWithMusicCount = [];
  List<Map<String, dynamic>> get playlistsWithMusicCount =>
      List.unmodifiable(_playlistsWithMusicCount);
  bool _isLoadingPlaylistsWithCount = false;
  bool get isLoadingPlaylistsWithCount => _isLoadingPlaylistsWithCount;
  bool _isReprocessingGenres = false;
  bool get isReprocessingGenres => _isReprocessingGenres;

  // 🎵 STATE
  List<MusicEntity> _libraryMusics = [];
  List<MusicEntity> _queueMusics = [];
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
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<int?>? _currentIndexSub;
  StreamSubscription<SequenceState>? _sequenceStateSub;
  StreamSubscription<AudioInterruptionEvent>? _audioInterruptionSub;
  StreamSubscription<void>? _becomingNoisySub;
  Duration? _sleepPausedRemaining;
  bool _restoringQueue = false;
  bool _isPersistingQueue = false;
  DateTime? _lastQueuePersistAt;
  Duration _lastPersistedPosition = Duration.zero;
  double? _volumeBeforeDuck;
  bool _resumeAfterInterruption = false;
  final List<PlaybackIssue> _playbackIssues = [];

  // 🎧 GAPLESS / CROSSFADE
  final PlaybackPreferences _playbackPrefs = PlaybackPreferences();
  PlaybackConfig _playbackConfig = const PlaybackConfig(
    gaplessEnabled: true,
    crossfadeEnabled: false,
    crossfadeSeconds: 0,
  );
  bool _isLoadingConfig = true;
  bool _isChangingTrack = false; // Lock para evitar mudanças múltiplas

  // =====================
  // GETTERS
  // =====================
  AudioPlayer get player => _player;
  List<MusicEntity> get libraryMusics => _libraryMusics;
  List<MusicEntity> get queueMusics => _queueMusics;
  MusicEntity? get currentMusic => _currentMusic;
  bool get isShuffled => _isShuffled;
  LoopMode get repeatMode => _repeatMode;
  double get currentSpeed => _currentSpeed;
  
  // Gapless/Crossfade getters
  bool get gaplessEnabled => _playbackConfig.gaplessEnabled;
  bool get crossfadeEnabled => _playbackConfig.crossfadeEnabled;
  int get crossfadeSeconds => _playbackConfig.crossfadeSeconds;
  Duration get crossfadeDuration => _playbackConfig.crossfadeDuration;
  bool get isCrossfadeActive => _playbackConfig.isCrossfadeActive;
  bool get isLoadingConfig => _isLoadingConfig;

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
  List<PlaybackIssue> get playbackIssues => List.unmodifiable(_playbackIssues);

  void clearPlaybackIssues() {
    if (_playbackIssues.isEmpty) return;
    _playbackIssues.clear();
    notifyListeners();
  }

  String? _currentGenre;
  Color? _currentGenreColor;

  String? get currentGenre => _currentGenre;
  Color? get currentGenreColor => _currentGenreColor;

  // =====================
  // INIT
  // =====================
  PlaylistViewModel({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _loadPlaybackConfig();
    _initAudioSession();
    _listenToSequenceChanges();

    _playingSub = _player.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();

      if (!playing) {
        _pauseSleepTimer();
        _persistPlaybackQueue(force: true);
      } else {
        _resumeSleepTimerIfNeeded();
      }
    });

    _currentIndexSub = _player.currentIndexStream.listen((_) {
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
    loadPlaylistsWithMusicCount();
  }

  // =====================
  // GAPLESS / CROSSFADE CONFIG
  // =====================
  Future<void> _loadPlaybackConfig() async {
    try {
      _playbackConfig = await _playbackPrefs.loadConfig();
    } catch (e) {
      AppLogger.warn(
        'PlaylistViewModel',
        'Falha ao carregar config de playback',
        error: e,
      );
    } finally {
      _isLoadingConfig = false;
      notifyListeners();
    }
  }

  Future<void> setGaplessEnabled(bool enabled) async {
    if (_playbackConfig.gaplessEnabled == enabled) return;
    await _playbackPrefs.setGaplessEnabled(enabled);
    _playbackConfig = PlaybackConfig(
      gaplessEnabled: enabled,
      crossfadeEnabled: _playbackConfig.crossfadeEnabled,
      crossfadeSeconds: _playbackConfig.crossfadeSeconds,
    );
    notifyListeners();
    // Reconfigurar fila com gapless
    if (_queueMusics.isNotEmpty) {
      await _setAudioSource(initialIndex: _player.currentIndex ?? 0);
    }
  }

  Future<void> setCrossfadeEnabled(bool enabled) async {
    if (_playbackConfig.crossfadeEnabled == enabled) return;
    await _playbackPrefs.setCrossfadeEnabled(enabled);
    _playbackConfig = PlaybackConfig(
      gaplessEnabled: _playbackConfig.gaplessEnabled,
      crossfadeEnabled: enabled,
      crossfadeSeconds: _playbackConfig.crossfadeSeconds,
    );
    notifyListeners();
  }

  Future<void> setCrossfadeSeconds(int seconds) async {
    final clamped = seconds.clamp(0, PlaybackPreferences.maxCrossfadeSeconds);
    if (_playbackConfig.crossfadeSeconds == clamped) return;
    await _playbackPrefs.setCrossfadeSeconds(clamped);
    _playbackConfig = PlaybackConfig(
      gaplessEnabled: _playbackConfig.gaplessEnabled,
      crossfadeEnabled: clamped > 0,
      crossfadeSeconds: clamped,
    );
    notifyListeners();
  }

  // =====================
  // AUDIO SESSION
  // =====================
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    await _audioInterruptionSub?.cancel();
    _audioInterruptionSub = session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _volumeBeforeDuck ??= _player.volume;
            await _player.setVolume((_volumeBeforeDuck! * 0.5).clamp(0.0, 1.0));
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _resumeAfterInterruption = _player.playing;
            if (_player.playing) {
              await _player.pause();
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            if (_volumeBeforeDuck != null) {
              await _player.setVolume(_volumeBeforeDuck!.clamp(0.0, 1.0));
              _volumeBeforeDuck = null;
            }
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (_resumeAfterInterruption) {
              _resumeAfterInterruption = false;
              await _player.play();
            }
            break;
        }
      }
    });

    await _becomingNoisySub?.cancel();
    _becomingNoisySub = session.becomingNoisyEventStream.listen((_) async {
      if (_player.playing) {
        _resumeAfterInterruption = false;
        await _player.pause();
      }
    });
  }

  // =====================
  // DATABASE — MUSICS
  // =====================
  Future<void> loadAllMusics() async {
    final allMusics = await _dbHelper.getAllMusicsV2();
    _libraryMusics = allMusics;

    if (_libraryMusics.isNotEmpty) {
      final restored = await _restorePlaybackQueue(allMusics);
      if (!restored) {
        _queueMusics = List<MusicEntity>.from(_libraryMusics);
        await _setAudioSource(initialIndex: 0);
      }
    } else {
      _queueMusics = [];
      await _dbHelper.clearPlaybackQueue();
    }

    notifyListeners();
    _persistPlaybackQueue();
  }

  Future<void> setQueueMusics(List<MusicEntity> musics) async {
    _queueMusics = musics;
    await _setAudioSource();
    await _persistPlaybackQueue();
    notifyListeners();
  }

  // =====================
  // DATABASE — PLAYLISTS
  // =====================

  Future<void> createPlaylist(String name) async {
    await _dbHelper.createPlaylist(name);
    await loadPlaylistsWithMusicCount(force: true);
    notifyListeners();
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _dbHelper.deletePlaylist(playlistId);
    await loadPlaylistsWithMusicCount(force: true);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getPlaylists() {
    return _dbHelper.getPlaylists();
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
      _playlistsWithMusicCount = await _dbHelper.getPlaylistsWithMusicCount();
    } finally {
      _isLoadingPlaylistsWithCount = false;
      notifyListeners();
    }
  }

  // =====================
  // PLAYLIST ↔ MÚSICAS
  // =====================

  Future<List<MusicEntity>> getMusicsFromPlaylistV2(int playlistId) {
    return _dbHelper.getMusicsFromPlaylistV2(playlistId);
  }

  Future<void> addMusicToPlaylistV2(int playlistId, int musicId) async {
    await _dbHelper.addMusicToPlaylistV2(playlistId, musicId);
    await loadPlaylistsWithMusicCount(force: true);
    notifyListeners();
  }

  Future<void> removeMusicFromPlaylist(int playlistId, int musicId) async {
    await _dbHelper.removeMusicFromPlaylistV2(playlistId, musicId);
    await loadPlaylistsWithMusicCount(force: true);
    notifyListeners();
  }

  // =====================
  // AUDIO SOURCE
  // =====================
  Future<void> _setAudioSource({int? initialIndex}) async {
    if (_queueMusics.isEmpty) return;

    final wasPlaying = _player.playing;
    final currentIndex = initialIndex ?? _player.currentIndex ?? 0;

    // 🎧 GAPLESS: Usar ConcatenatingAudioSource para transições suaves
    final children = <AudioSource>[];

    for (final music in _queueMusics) {
      final uri = _resolveAudioUri(music);

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

    try {
      // 🎧 GAPLESS: Usar lista direta com ConcatenatingAudioSource internamente
      // just_audio automaticamente usa gapless quando as faixas estão na mesma playlist
      await _player.setAudioSources(
        children,
        initialIndex: currentIndex.clamp(0, children.length - 1),
      );
    } catch (e, st) {
      final idx = currentIndex.clamp(0, _queueMusics.length - 1);
      final music = _queueMusics.isEmpty ? null : _queueMusics[idx];
      _reportPlaybackIssue(
        stage: 'set_audio_source',
        error: e,
        stackTrace: st,
        music: music,
      );
      return;
    }

    try {
      await _player.setShuffleModeEnabled(_isShuffled);
      if (wasPlaying) {
        await _player.play();
      }
    } catch (e, st) {
      final idx = (_player.currentIndex ?? currentIndex).clamp(
        0,
        _queueMusics.length - 1,
      );
      final music = _queueMusics.isEmpty ? null : _queueMusics[idx];
      _reportPlaybackIssue(
        stage: 'resume_after_set_source',
        error: e,
        stackTrace: st,
        music: music,
      );
    }
    unawaited(_persistPlaybackQueue());
  }

  Uri _resolveAudioUri(MusicEntity music) {
    final raw = music.audioUrl.trim();
    if (raw.isEmpty) return Uri();

    if (raw.startsWith('content://') ||
        raw.startsWith('file://') ||
        raw.startsWith('http://') ||
        raw.startsWith('https://')) {
      return Uri.parse(raw);
    }

    // Android scoped storage: MediaStore content URI is more reliable than file path.
    if (raw.startsWith('/') && music.sourceId != null) {
      return Uri.parse('content://media/external/audio/media/${music.sourceId}');
    }

    final isWindowsPath = RegExp(r'^[a-zA-Z]:\\').hasMatch(raw) ||
        raw.startsWith('\\\\');
    if (isWindowsPath) return Uri.file(raw);

    if (raw.startsWith('/')) return Uri.file(raw);
    return Uri.parse(raw);
  }

  // =====================
  // PLAYER LISTENER (RECENTES)
  // =====================
  void _listenToSequenceChanges() {
    _sequenceStateSub = _player.sequenceStateStream.listen((sequenceState) async {
      // Lock para evitar processamento múltiplo simultâneo
      if (_isChangingTrack) return;
      
      final index = sequenceState.currentIndex;
      if (index == null) return;
      if (index < 0 || index >= _queueMusics.length) return;

      final newMusic = _queueMusics[index];

      // Comparar por ID ou audioUrl para evitar falsos positivos
      final currentId = _currentMusic?.id ?? _currentMusic?.audioUrl;
      final newId = newMusic.id ?? newMusic.audioUrl;

      if (currentId != newId) {
        _isChangingTrack = true;
        
        try {
          _currentMusic = newMusic;

          // 🎧 CROSSFADE: Aplicar fade in de forma NÃO BLOQUEANTE
          // O listener continua imediatamente para atualizar a UI
          if (_playbackConfig.isCrossfadeActive && _player.playing) {
            unawaited(_applyCrossfade());
          }

          // 🎼 gênero atual
          final resolvedGenre = _resolveCurrentGenre(newMusic);
          _currentGenre = resolvedGenre;

          // 🎨 cor do gênero
          if (resolvedGenre != null && resolvedGenre.isNotEmpty) {
            _currentGenreColor = GenreColorHelper.getColor(resolvedGenre);
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
        } finally {
          _isChangingTrack = false;
        }
      }
    });
  }

  // 🎧 CROSSFADE: Aplica fade in suave na nova faixa (NÃO BLOQUEANTE)
  // Usamos Timer.periodic para não bloquear o listener do sequenceState
  Timer? _crossfadeTimer;
  bool _isApplyingCrossfade = false;
  
  Future<void> _applyCrossfade() async {
    if (!_playbackConfig.isCrossfadeActive || _isApplyingCrossfade) return;
    
    _isApplyingCrossfade = true;
    _crossfadeTimer?.cancel();
    
    try {
      final crossfadeSeconds = _playbackConfig.crossfadeSeconds;
      
      if (crossfadeSeconds <= 0) return;

      // Fade in gradual da nova faixa usando Timer (não bloqueante)
      const steps = 20;
      final stepDuration = (crossfadeSeconds * 1000 / steps).round();
      var currentStep = 0;

      // Volume inicial bem baixo
      await _player.setVolume(0.0);
      
      // Pequeno delay inicial
      await Future.delayed(const Duration(milliseconds: 30));

      // Timer não bloqueante para fade in
      _crossfadeTimer = Timer.periodic(
        Duration(milliseconds: stepDuration),
        (timer) {
          currentStep++;
          
          if (currentStep >= steps || !_player.playing) {
            timer.cancel();
            _player.setVolume(1.0); // Garante volume máximo
            _isApplyingCrossfade = false;
            return;
          }
          
          final targetVolume = currentStep / steps;
          _player.setVolume(targetVolume);
        },
      );
    } catch (_) {
      _crossfadeTimer?.cancel();
      await _player.setVolume(1.0);
      _isApplyingCrossfade = false;
    }
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
      _queueMusics.map((e) => e.audioUrl).toList(),
      queue.map((e) => e.audioUrl).toList(),
    );

    try {
      if (isDifferentQueue) {
        _queueMusics = List.from(queue);
        await _setAudioSource(initialIndex: index);
      } else {
        await _player.seek(Duration.zero, index: index);
      }

      if (_isShuffled) {
        await _player.setShuffleModeEnabled(true);
        await _player.shuffle();
      }

      _currentMusic = _queueMusics[index];
      if (kDebugMode) {
        AppLogger.info('PlaylistViewModel', 'play called');
      }
      await _player.play();

      _persistPlaybackQueue();
      notifyListeners();
    } catch (e, st) {
      final safeIndex = index.clamp(0, queue.length - 1);
      _reportPlaybackIssue(
        stage: 'play_music',
        error: e,
        stackTrace: st,
        music: queue[safeIndex],
      );
      return;
    }
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
    if (_queueMusics.isEmpty) return;
    if (oldIndex < 0 || oldIndex >= _queueMusics.length) return;
    if (newIndex < 0 || newIndex > _queueMusics.length) return;

    final currentId = _currentMusic?.id;
    final targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    final moved = _queueMusics.removeAt(oldIndex);
    _queueMusics.insert(targetIndex, moved);

    var nextCurrentIndex = 0;
    if (currentId != null) {
      final idx = _queueMusics.indexWhere((m) => m.id == currentId);
      nextCurrentIndex = idx == -1 ? 0 : idx;
    } else {
      nextCurrentIndex = targetIndex.clamp(0, _queueMusics.length - 1);
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

    final queueIndex =
        _queueMusics.indexWhere((m) => m.audioUrl == music.audioUrl);
    if (queueIndex != -1) {
      _queueMusics[queueIndex] = music.copyWith(isFavorite: newValue);
    }

    final libraryIndex =
        _libraryMusics.indexWhere((m) => m.audioUrl == music.audioUrl);
    if (libraryIndex != -1) {
      _libraryMusics[libraryIndex] = music.copyWith(isFavorite: newValue);
    }

    if (_currentMusic?.audioUrl == music.audioUrl && queueIndex != -1) {
      _currentMusic = _queueMusics[queueIndex];
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

  Future<int> runGenreReprocess() async {
    if (_isReprocessingGenres) return 0;
    _isReprocessingGenres = true;
    notifyListeners();
    try {
      final updated = await _dbHelper.reprocessGenresBatch();
      await loadAllMusics();
      return updated;
    } finally {
      _isReprocessingGenres = false;
      notifyListeners();
    }
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
    _crossfadeTimer?.cancel(); // 🎧 Cancela crossfade timer
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _playingSub?.cancel();
    _currentIndexSub?.cancel();
    _sequenceStateSub?.cancel();
    _audioInterruptionSub?.cancel();
    _becomingNoisySub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _reportPlaybackIssue({
    required String stage,
    required Object error,
    StackTrace? stackTrace,
    MusicEntity? music,
  }) {
    final issue = PlaybackIssue(
      when: DateTime.now(),
      stage: stage,
      audioUrl: music?.audioUrl,
      title: music?.title,
      message: error.toString(),
    );
    _playbackIssues.insert(0, issue);
    if (_playbackIssues.length > 30) {
      _playbackIssues.removeRange(30, _playbackIssues.length);
    }

    AppLogger.error(
      'PlaybackIssue',
      '[$stage] ${music?.title ?? 'unknown'} | ${music?.audioUrl ?? '-'}',
      error: error,
      stackTrace: stackTrace,
    );
    notifyListeners();
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
    try {
      _queueMusics = restoredQueue;

      final rawIndex = saved['currentIndex'] as int? ?? 0;
      final currentIndex = rawIndex.clamp(0, _queueMusics.length - 1);
      await _setAudioSource(initialIndex: currentIndex);

      final positionMs = saved['positionMs'] as int? ?? 0;
      if (positionMs > 0) {
        await _player.seek(
          Duration(milliseconds: positionMs),
          index: currentIndex,
        );
      }
    } finally {
      _restoringQueue = false;
    }
    unawaited(_persistPlaybackQueue());
    return true;
  }

  Future<void> _persistPlaybackQueue({bool force = false}) async {
    if (_restoringQueue) return;
    if (_queueMusics.isEmpty) {
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

    final currentIndex = (_player.currentIndex ?? 0).clamp(0, _queueMusics.length - 1);
    final positionMs = _player.position.inMilliseconds;

    _isPersistingQueue = true;
    try {
      await _dbHelper.savePlaybackQueue(
        audioUrls: _queueMusics.map((m) => m.audioUrl).toList(),
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

    if (_queueMusics.isEmpty) {
      await _dbHelper.clearPlaybackQueue();
      return;
    }

    final currentIndex = (_player.currentIndex ?? 0).clamp(0, _queueMusics.length - 1);
    final positionMs = _player.position.inMilliseconds;
    final urls = _queueMusics.map((m) => m.audioUrl).toList();

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
    if (_queueMusics.isEmpty) return;
    final index = _player.currentIndex ?? 0;
    if (index < 0 || index >= _queueMusics.length) return;

    final pos = position ?? _player.position;
    final currentMs = _queueMusics[index].duration ?? 0;
    if (currentMs <= 0) return;

    var remainingMs = (currentMs - pos.inMilliseconds).clamp(0, currentMs);

    for (var i = index + 1; i < _queueMusics.length; i++) {
      remainingMs += _queueMusics[i].duration ?? 0;
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

    for (final m in _libraryMusics) {
      if (kDebugMode) {
        debugPrint('folder item: ${m.title} | ${m.folderPath}');
      }
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
    for (final m in _libraryMusics) {
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

  String? _resolveCurrentGenre(MusicEntity music) {
    final rawGenre = music.genre?.trim();
    if (rawGenre != null && rawGenre.isNotEmpty) return rawGenre;

    final folder = music.folderPath?.trim();
    if (folder != null && folder.isNotEmpty) {
      final normalizedPath = folder.replaceAll('\\', '/');
      final segments = normalizedPath
          .split('/')
          .where((segment) => segment.trim().isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        return segments.last.trim();
      }
    }

    return _inferGenreFromText(music);
  }

  String? _inferGenreFromText(MusicEntity music) {
    final text = _normalizeForGenreGuess(
      '${music.title} ${music.artist} ${music.album ?? ''}',
    );

    if (_containsAnyToken(text, const ['mozart', 'bach', 'beethoven', 'chopin'])) {
      return 'Classica';
    }
    if (_containsAnyToken(text, const ['samba', 'pagode', 'axe'])) {
      return 'Samba/Pagode';
    }
    if (_containsAnyToken(text, const ['forro', 'piseiro', 'sertanejo', 'arrocha'])) {
      return 'Sertanejo/Forro';
    }
    if (_containsAnyToken(text, const ['gospel', 'worship', 'louvor'])) {
      return 'Gospel';
    }
    if (_containsAnyToken(text, const ['rock', 'metal', 'punk'])) {
      return 'Rock';
    }
    if (_containsAnyToken(text, const ['funk', 'trap', 'hip hop', 'rap'])) {
      return 'Hip Hop/Funk';
    }
    if (_containsAnyToken(text, const ['jazz', 'blues', 'bossa'])) {
      return 'Jazz/Blues';
    }
    return null;
  }

  String _normalizeForGenreGuess(String value) {
    final lowercase = value.toLowerCase();
    final sb = StringBuffer();
    const map = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    for (final rune in lowercase.runes) {
      final ch = String.fromCharCode(rune);
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }

  bool _containsAnyToken(String value, List<String> tokens) {
    for (final token in tokens) {
      if (value.contains(token)) return true;
    }
    return false;
  }
}

class PlaybackIssue {
  final DateTime when;
  final String stage;
  final String? audioUrl;
  final String? title;
  final String message;

  const PlaybackIssue({
    required this.when,
    required this.stage,
    required this.audioUrl,
    required this.title,
    required this.message,
  });
}




