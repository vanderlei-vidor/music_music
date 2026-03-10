import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:music_music/core/audio/app_audio_handler.dart';
import 'package:music_music/core/observability/app_logger.dart';
import 'package:music_music/core/preferences/playback_preferences.dart';
import 'package:music_music/core/services/music_widget_manager.dart';
import 'package:music_music/core/ui/genre_colors.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/controllers/library_controller.dart';
import 'package:music_music/features/playlists/controllers/playback_queue_persistence.dart';
import 'package:music_music/features/playlists/controllers/queue_controller.dart';
import 'package:music_music/features/playlists/controllers/sleep_timer_controller.dart';
import 'package:music_music/features/playlists/models/playback_issue.dart';
import 'package:music_music/features/playlists/models/sleep_timer_mode.dart';
import 'package:music_music/features/playlists/utils/playlist_genre_utils.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController({
    required AudioHandler handler,
    required PlaybackQueuePersistence queuePersistence,
    required LibraryController libraryController,
  })  : _handler = handler,
        _queuePersistence = queuePersistence,
        _libraryController = libraryController {
    _queueController = QueueController(
      rawQueueIndex: () => _handler.playbackState.value.queueIndex ?? 0,
    );
    _sleepTimerController = SleepTimerController(
      onExpire: () => pause(),
      onNotify: notifyListeners,
      isPlaying: () => _isPlaying,
      currentPosition: () => _lastKnownPosition,
      currentTrackDurationMs: () => _currentMusic?.duration,
      queueDurationsMs: () => _queueMusics.map((m) => m.duration).toList(),
      currentIndex: () => _queueController.currentIndex,
    );
    _loadPlaybackConfig();
    _initAudioSession();
    _setupPlayerListeners();
  }

  final AudioHandler _handler;
  final PlaybackQueuePersistence _queuePersistence;
  final LibraryController _libraryController;

  late final QueueController _queueController;
  late final SleepTimerController _sleepTimerController;
  final PlaybackPreferences _playbackPrefs = PlaybackPreferences();
  PlaybackConfig _playbackConfig = const PlaybackConfig(
    gaplessEnabled: true,
    crossfadeEnabled: false,
    crossfadeSeconds: 0,
  );
  bool _isLoadingConfig = true;
  bool _isChangingTrack = false;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlaybackState>? _playbackStateSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<List<MediaItem>>? _queueSub;
  StreamSubscription<AudioInterruptionEvent>? _audioInterruptionSub;
  StreamSubscription<void>? _becomingNoisySub;
  StreamSubscription<String>? _widgetActionSub;

  Duration _lastKnownPosition = Duration.zero;
  double? _volumeBeforeDuck;
  double _currentVolume = 1.0;
  bool _resumeAfterInterruption = false;
  final List<PlaybackIssue> _playbackIssues = [];
  int _crossfadeRunId = 0;

  List<MusicEntity> get _queueMusics => _queueController.queue;
  set _queueMusics(List<MusicEntity> value) {
    _queueController.queue = value;
  }

  bool get _isShuffled => _queueController.isShuffled;
  set _isShuffled(bool value) {
    _queueController.isShuffled = value;
  }

  LoopMode get _repeatMode => _queueController.repeatMode;
  set _repeatMode(LoopMode value) {
    _queueController.repeatMode = value;
  }

  MusicEntity? _currentMusic;
  bool _isPlaying = false;
  double _currentSpeed = 1.0;

  Color _currentDominantColor = Colors.blueGrey.shade600;
  String? _currentGenre;
  Color? _currentGenreColor;

  AudioHandler get handler => _handler;
  List<MusicEntity> get queueMusics => _queueMusics;
  MusicEntity? get currentMusic => _currentMusic;
  bool get isShuffled => _isShuffled;
  LoopMode get repeatMode => _repeatMode;
  double get currentSpeed => _currentSpeed;
  bool get isPlaying => _isPlaying;
  int get currentIndex => _queueController.currentIndex;
  Duration get currentPosition => _lastKnownPosition;
  double get currentVolume => _currentVolume;
  Color get currentDominantColor => _currentDominantColor;
  String? get currentGenre => _currentGenre;
  Color? get currentGenreColor => _currentGenreColor;
  List<PlaybackIssue> get playbackIssues => List.unmodifiable(_playbackIssues);

  bool get gaplessEnabled => _playbackConfig.gaplessEnabled;
  bool get crossfadeEnabled => _playbackConfig.crossfadeEnabled;
  int get crossfadeSeconds => _playbackConfig.crossfadeSeconds;
  Duration get crossfadeDuration => _playbackConfig.crossfadeDuration;
  bool get isCrossfadeActive => _playbackConfig.isCrossfadeActive;
  bool get isLoadingConfig => _isLoadingConfig;

  Stream<Duration> get positionStream {
    final handler = _handler;
    if (handler is AppAudioHandler) {
      return handler.positionStream;
    }
    return AudioService.position;
  }

  Stream<bool> get playingStream =>
      _handler.playbackState.map((s) => s.playing).distinct();
  Stream<double> get speedStream =>
      _handler.playbackState.map((s) => s.speed).distinct();

  Duration? get sleepDuration => _sleepTimerController.duration;
  bool get hasSleepTimer => _sleepTimerController.hasActiveTimer;
  DateTime? get sleepEndTime => _sleepTimerController.endTime;
  SleepTimerMode get sleepMode => _sleepTimerController.mode;
  Duration? get sleepRemaining => _sleepTimerController.remaining;

  void clearPlaybackIssues() {
    if (_playbackIssues.isEmpty) return;
    _playbackIssues.clear();
    notifyListeners();
  }

  void bindWidgetActionStream(Stream<String>? stream) {
    _widgetActionSub?.cancel();
    if (stream == null) return;
    _widgetActionSub = stream.listen((action) {
      unawaited(_handleWidgetAction(action));
    });
  }

  Future<void> applyLibraryMusics(List<MusicEntity> libraryMusics) async {
    if (libraryMusics.isNotEmpty) {
      final restored = await _restorePlaybackQueue(libraryMusics);
      if (!restored) {
        _queueMusics = List<MusicEntity>.from(libraryMusics);
        await _setAudioSource(initialIndex: 0);
      }
    } else {
      _queueMusics = [];
      await _queuePersistence.clear();
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

  Future<void> _loadPlaybackConfig() async {
    try {
      _playbackConfig = await _playbackPrefs.loadConfig();
    } catch (e) {
      AppLogger.warn(
        'PlaybackController',
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
    if (_queueMusics.isNotEmpty) {
      await _setAudioSource(initialIndex: _queueController.currentIndex);
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

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    await _audioInterruptionSub?.cancel();
    _audioInterruptionSub = session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _volumeBeforeDuck ??= _currentVolume;
            final ducked = (_volumeBeforeDuck! * 0.5).clamp(0.0, 1.0);
            await _setHandlerVolume(ducked);
            _currentVolume = ducked;
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _resumeAfterInterruption = _isPlaying;
            if (_isPlaying) {
              await _handler.pause();
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            if (_volumeBeforeDuck != null) {
              final restored = _volumeBeforeDuck!.clamp(0.0, 1.0);
              await _setHandlerVolume(restored);
              _currentVolume = restored;
              _volumeBeforeDuck = null;
            }
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (_resumeAfterInterruption) {
              _resumeAfterInterruption = false;
              await _handler.play();
            }
            break;
        }
      }
    });

    await _becomingNoisySub?.cancel();
    _becomingNoisySub = session.becomingNoisyEventStream.listen((_) async {
      if (_isPlaying) {
        _resumeAfterInterruption = false;
        await _handler.pause();
      }
    });
  }

  void _setupPlayerListeners() {
    _playbackStateSub = _handler.playbackState.listen((state) {
      final playing = state.playing;
      var shouldNotify = false;
      if ((_currentSpeed - state.speed).abs() > 0.001) {
        _currentSpeed = state.speed;
        shouldNotify = true;
      }
      if (_isPlaying != playing) {
        _isPlaying = playing;
        shouldNotify = true;
        unawaited(MusicWidgetManager.updatePlayerPlayPause(playing));
      }
      if (shouldNotify) {
        notifyListeners();
      }

      if (!playing) {
        _sleepTimerController.handlePlayingChanged(false);
        _persistPlaybackQueue(force: true);
      } else {
        _sleepTimerController.handlePlayingChanged(true);
      }

      if (state.processingState == AudioProcessingState.completed) {
        _sleepTimerController.handlePlaybackCompleted();
      }
    });

    _queueSub = _handler.queue.listen((_) {
      _persistPlaybackQueue();
    });

    _positionSub = positionStream.listen((position) {
      _lastKnownPosition = position;
      _persistPlaybackQueue();

      _sleepTimerController.handlePosition(position);
    });

    _mediaItemSub = _handler.mediaItem.listen((item) {
      if (item == null) return;
      final music = _musicFromMediaItem(item);
      if (music == null) return;
      _handleMediaItemChange(music);
    });
  }

  Future<void> _setAudioSource({int? initialIndex}) async {
    if (_queueMusics.isEmpty) return;

    final wasPlaying = _isPlaying;
    final currentIndex = initialIndex ?? _queueController.currentIndex;

    final items = _queueMusics.map(_musicToMediaItem).toList();

    try {
      await _handler.updateQueue(items);
      await _handler.skipToQueueItem(
        currentIndex.clamp(0, items.length - 1),
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
      await _handler.setShuffleMode(
        _isShuffled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      );
      if (wasPlaying) {
        await _handler.play();
      }
    } catch (e, st) {
      final idx = currentIndex.clamp(0, _queueMusics.length - 1);
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

  Future<void> _handleMediaItemChange(MusicEntity newMusic) async {
    if (_isChangingTrack) return;

    final currentId = _currentMusic?.id ?? _currentMusic?.audioUrl;
    final newId = newMusic.id ?? newMusic.audioUrl;

    if (currentId == newId) return;

    _isChangingTrack = true;
    try {
      _currentMusic = newMusic;

      if (_playbackConfig.isCrossfadeActive && _isPlaying) {
        unawaited(_applyCrossfade());
      }

      final resolvedGenre = PlaylistGenreUtils.resolveCurrentGenre(newMusic);
      _currentGenre = resolvedGenre;

      if (resolvedGenre != null && resolvedGenre.isNotEmpty) {
        _currentGenreColor = GenreColorHelper.getColor(resolvedGenre);
      } else {
        _currentGenreColor = null;
      }

      await _updateDominantColor(newMusic);

      _sleepTimerController.handleTrackChanged();

      if (newMusic.id != null) {
        await _libraryController.registerRecentPlay(newMusic.id!);
      }

      unawaited(_updatePlayerWidget(newMusic));
      notifyListeners();
    } finally {
      _isChangingTrack = false;
    }
  }

  MusicEntity? _musicFromMediaItem(MediaItem item) {
    final extras = item.extras ?? const <String, dynamic>{};
    final audioUrl = extras['audioUrl']?.toString();
    if (audioUrl == null || audioUrl.isEmpty) return null;

    final existing =
        _queueMusics.where((m) => m.audioUrl == audioUrl).firstOrNull;
    if (existing != null) return existing;

    return MusicEntity(
      id: int.tryParse(item.id),
      sourceId: extras['sourceId'] as int?,
      title: item.title,
      artist: item.artist ?? 'Desconhecido',
      album: item.album,
      artworkUrl: extras['artworkUrl']?.toString(),
      audioUrl: audioUrl,
      duration: item.duration?.inMilliseconds,
    );
  }

  MediaItem _musicToMediaItem(MusicEntity music) {
    return MediaItem(
      id: music.id?.toString() ?? music.audioUrl,
      title: music.title,
      artist: music.artist,
      album: music.album,
      artUri: music.artworkUrl != null ? Uri.tryParse(music.artworkUrl!) : null,
      duration: music.duration != null
          ? Duration(milliseconds: music.duration!)
          : null,
      extras: {
        'audioUrl': music.audioUrl,
        'sourceId': music.sourceId,
        'artworkUrl': music.artworkUrl,
      },
    );
  }

  Future<void> _updatePlayerWidget(MusicEntity music) async {
    try {
      await MusicWidgetManager.updatePlayerWidget(
        currentMusic: music,
        isPlaying: _isPlaying,
        artworkPath: music.artworkUrl,
        isShuffled: _isShuffled,
        repeatMode: _repeatMode.index,
        isFavorite: music.isFavorite,
        queueTitles: _queueController.titles(limit: 1000),
        queueCount: _queueController.queueCount,
        themeColor: _currentDominantColor.value,
        queueStartPosition: 1,
        currentPosition: _queueController.currentPosition(),
        totalTracks: _queueController.queueCount,
      );
    } catch (e, st) {
      AppLogger.warn(
        'PlaybackController',
        'Falha ao atualizar widget player',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _handleWidgetAction(String action) async {
    try {
      if (action.startsWith('play_index:')) {
        final raw = action.substring('play_index:'.length);
        final oneBasedIndex = int.tryParse(raw);
        if (oneBasedIndex != null) {
          await _playFromQueuePosition(oneBasedIndex);
        }
        return;
      }

      switch (action) {
        case 'play_pause':
          await _togglePlayPause();
          break;
        case 'next':
          await nextMusic();
          break;
        case 'previous':
          await previousMusic();
          break;
        case 'shuffle':
          await toggleShuffle();
          break;
        case 'repeat':
          await toggleRepeatMode();
          break;
        case 'favorite':
          final music = _currentMusic;
          if (music != null) {
            await toggleFavorite(music);
          }
          break;
      }
    } catch (e, st) {
      AppLogger.warn(
        'PlaybackController',
        'Falha ao processar acao do widget: $action',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _playFromQueuePosition(int oneBasedIndex) async {
    if (_queueMusics.isEmpty) return;
    final index = (oneBasedIndex - 1).clamp(0, _queueMusics.length - 1);
    await playMusic(_queueMusics, index);
  }

  Future<void> _applyCrossfade() async {
    if (!_playbackConfig.isCrossfadeActive) return;

    final crossfadeSeconds = _playbackConfig.crossfadeSeconds;
    if (crossfadeSeconds <= 0) return;

    final runId = ++_crossfadeRunId;
    final targetVolume = _currentVolume.clamp(0.0, 1.0);
    if (targetVolume <= 0.0) {
      return;
    }

    try {
      const steps = 20;
      final stepMs = (crossfadeSeconds * 1000 / steps).round().clamp(16, 1000);
      await _setHandlerVolume(0.0);
      _currentVolume = 0.0;

      for (var step = 1; step <= steps; step++) {
        if (runId != _crossfadeRunId || !_isPlaying) return;
        await Future.delayed(Duration(milliseconds: stepMs));
        if (runId != _crossfadeRunId || !_isPlaying) return;

        final volume = (targetVolume * (step / steps)).clamp(0.0, 1.0);
        await _setHandlerVolume(volume);
        _currentVolume = volume;
      }
    } catch (_) {
      await _setHandlerVolume(targetVolume);
      _currentVolume = targetVolume;
    }
  }

  Future<void> play() async {
    await _handler.play();
  }

  Future<void> pause() async {
    await _handler.pause();
  }

  void playPause() {
    unawaited(_togglePlayPause());
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> playMusic(List<MusicEntity> queue, int index) async {
    if (queue.isEmpty) return;

    final isDifferentQueue = _queueController.replaceIfDifferent(queue);

    try {
      if (isDifferentQueue) {
        await _setAudioSource(initialIndex: index);
      } else {
        await _handler.skipToQueueItem(index);
        await _handler.seek(Duration.zero);
      }

      if (_isShuffled) {
        await _handler.setShuffleMode(AudioServiceShuffleMode.all);
      }

      _currentMusic = _queueMusics[index];
      unawaited(_updatePlayerWidget(_currentMusic!));
      if (kDebugMode) {
        AppLogger.info('PlaybackController', 'play called');
      }
      await _handler.play();

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

  Future<void> nextMusic() async {
    await _handler.skipToNext();
    _persistPlaybackQueue();
  }

  Future<void> previousMusic() async {
    await _handler.skipToPrevious();
    _persistPlaybackQueue();
  }

  Future<void> seek(Duration position) async {
    await _handler.seek(position);
    _persistPlaybackQueue();
  }

  Future<void> toggleShuffle() async {
    _isShuffled = !_isShuffled;

    await _handler.setShuffleMode(
      _isShuffled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
    if (!_isShuffled) {
      await _setAudioSource(initialIndex: _queueController.currentIndex);
    }

    final current = _currentMusic;
    if (current != null) {
      unawaited(_updatePlayerWidget(current));
    } else {
      unawaited(
        MusicWidgetManager.updatePlayerControlsState(
          isShuffled: _isShuffled,
          repeatMode: _repeatMode.index,
          isFavorite: false,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> toggleRepeatMode() async {
    if (_repeatMode == LoopMode.off) {
      _repeatMode = LoopMode.all;
    } else if (_repeatMode == LoopMode.all) {
      _repeatMode = LoopMode.one;
    } else {
      _repeatMode = LoopMode.off;
    }

    await _handler.setRepeatMode(_repeatModeToService(_repeatMode));
    final current = _currentMusic;
    if (current != null) {
      unawaited(_updatePlayerWidget(current));
    } else {
      unawaited(
        MusicWidgetManager.updatePlayerControlsState(
          isShuffled: _isShuffled,
          repeatMode: _repeatMode.index,
          isFavorite: false,
        ),
      );
    }
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

    final nextCurrentIndex = _queueController.reorder(
      oldIndex: oldIndex,
      newIndex: newIndex,
      currentMusicId: _currentMusic?.id,
    );

    await _setAudioSource(initialIndex: nextCurrentIndex);
    notifyListeners();
    _persistPlaybackQueue();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (speed < 0.5 || speed > 2.0) return;

    _currentSpeed = speed;
    await _handler.setSpeed(speed);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    if (volume < 0 || volume > 1) return;
    await _setHandlerVolume(volume);
    _currentVolume = volume;
    notifyListeners();
  }

  Future<bool> toggleFavorite(MusicEntity music) async {
    final newValue = !music.isFavorite;

    await _libraryController.applyFavoriteChange(music, newValue);

    final queueIndex = _queueController.indexOfAudioUrl(music.audioUrl);
    if (queueIndex != -1) {
      _queueMusics[queueIndex] = music.copyWith(isFavorite: newValue);
    }

    if (_currentMusic?.audioUrl == music.audioUrl && queueIndex != -1) {
      _currentMusic = _queueMusics[queueIndex];
    }

    final current = _currentMusic;
    if (current != null) {
      unawaited(_updatePlayerWidget(current));
    } else {
      unawaited(
        MusicWidgetManager.updatePlayerControlsState(
          isShuffled: _isShuffled,
          repeatMode: _repeatMode.index,
          isFavorite: false,
        ),
      );
    }
    notifyListeners();

    return newValue;
  }

  void setSleepTimer(Duration duration) {
    _sleepTimerController.setSleepTimer(duration);
  }

  void cancelSleepTimer() {
    _sleepTimerController.cancel();
  }

  void setSleepTimerEndOfSong() {
    _sleepTimerController.setEndOfSong();
  }

  void setSleepTimerEndOfPlaylist() {
    _sleepTimerController.setEndOfPlaylist();
  }

  void setDominantColor(Color color) {
    _currentDominantColor = color;
    notifyListeners();
  }

  Future<void> _updateDominantColor(MusicEntity music) async {
    final artwork = music.artworkUrl;
    final fallbackColor = Colors.blueGrey.shade600;

    if (artwork == null || artwork.isEmpty) {
      _currentDominantColor = fallbackColor;
      debugPrint('sem artwork -> fallback | musica: ${music.title}');
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

      debugPrint('nova cor: $_currentDominantColor | musica: ${music.title}');
    } catch (e) {
      debugPrint('erro palette: $e');
      _currentDominantColor = fallbackColor;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_persistPlaybackQueueOnDispose());
    _sleepTimerController.dispose();
    _crossfadeRunId++;
    _positionSub?.cancel();
    _playbackStateSub?.cancel();
    _mediaItemSub?.cancel();
    _queueSub?.cancel();
    _audioInterruptionSub?.cancel();
    _becomingNoisySub?.cancel();
    _widgetActionSub?.cancel();
    super.dispose();
  }

  AudioServiceRepeatMode _repeatModeToService(LoopMode mode) {
    switch (mode) {
      case LoopMode.one:
        return AudioServiceRepeatMode.one;
      case LoopMode.all:
        return AudioServiceRepeatMode.all;
      case LoopMode.off:
      default:
        return AudioServiceRepeatMode.none;
    }
  }

  Future<void> _setHandlerVolume(double volume) async {
    await _handler.customAction('set_volume', {'volume': volume});
  }

  void _reportPlaybackIssue({
    required String stage,
    required Object error,
    StackTrace? stackTrace,
    MusicEntity? music,
  }) {
    final issue = PlaybackIssue.fromMusic(
      stage: stage,
      error: error,
      music: music,
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

  Future<bool> _restorePlaybackQueue(List<MusicEntity> allMusics) async {
    final restored = await _queuePersistence.restoreQueue(allMusics);
    if (restored == null) return false;

    _queueMusics = restored.queue;
    await _setAudioSource(initialIndex: restored.currentIndex);

    final positionMs = restored.positionMs;
    if (positionMs > 0) {
      await _handler.seek(Duration(milliseconds: positionMs));
    }

    unawaited(_persistPlaybackQueue());
    return true;
  }

  Future<void> _persistPlaybackQueue({bool force = false}) async {
    if (_queuePersistence.isRestoring) return;
    await _queuePersistence.saveQueue(
      queue: _queueMusics,
      currentIndex: _queueController.currentIndex,
      position: _lastKnownPosition,
      force: force,
    );
  }

  Future<void> _persistPlaybackQueueOnDispose() async {
    await _queuePersistence.saveQueue(
      queue: _queueMusics,
      currentIndex: _queueController.currentIndex,
      position: _lastKnownPosition,
      force: true,
    );
  }
}
