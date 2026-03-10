import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_music/core/audio/playback_queue_store.dart';
import 'package:music_music/core/services/music_widget_manager.dart';
import 'package:music_music/data/local/database_helper.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/player/equalizer/equalizer_backend.dart';
import 'package:music_music/features/player/equalizer/equalizer_models.dart';

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  final EqualizerBackend _eqBackend;
  StreamSubscription<PlaybackEvent>? _eventSub;
  StreamSubscription<int?>? _indexSub;
  bool _restoring = false;
  bool _lastWidgetPlaying = false;
  AudioServiceRepeatMode _lastWidgetRepeatMode = AudioServiceRepeatMode.none;
  AudioServiceShuffleMode _lastWidgetShuffleMode = AudioServiceShuffleMode.none;

  AppAudioHandler({
    required AudioPlayer player,
    required EqualizerBackend eqBackend,
  }) : _player = player,
       _eqBackend = eqBackend {
    _eqBackend.attachPlayer(_player);
    _eventSub = _player.playbackEventStream.listen(_broadcastState);
    _indexSub = _player.currentIndexStream.listen(_syncMediaItem);
    unawaited(_maybeRestoreQueue());
  }

  Stream<Duration> get positionStream => _player.positionStream;

  bool get _supportsWidgets =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    this.queue.add(queue);
    final sources = queue.map(_mediaItemToSource).toList();
    if (sources.isEmpty) {
      await _player.stop();
      return;
    }
    await _player.setAudioSources(
      sources,
      initialIndex: 0,
      initialPosition: Duration.zero,
    );
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (queue.value.isEmpty) return;
    final safeIndex = index.clamp(0, queue.value.length - 1);
    await _player.seek(Duration.zero, index: safeIndex);
  }

  @override
  Future<void> play() async {
    if (queue.value.isEmpty) {
      await _maybeRestoreQueue();
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
    if (enabled) {
      await _player.shuffle();
    }
    playbackState.add(
      playbackState.value.copyWith(shuffleMode: shuffleMode),
    );
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode = switch (repeatMode) {
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all => LoopMode.all,
      _ => LoopMode.off,
    };
    await _player.setLoopMode(loopMode);
    playbackState.add(
      playbackState.value.copyWith(repeatMode: repeatMode),
    );
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'set_volume':
        final volume = _toDouble(extras?['volume']) ?? 1.0;
        await _player.setVolume(volume.clamp(0.0, 1.0));
        return true;
      case 'toggle_shuffle':
        final nextShuffle = playbackState.value.shuffleMode ==
                AudioServiceShuffleMode.all
            ? AudioServiceShuffleMode.none
            : AudioServiceShuffleMode.all;
        await setShuffleMode(nextShuffle);
        unawaited(_updateWidgetControlsState());
        return true;
      case 'toggle_repeat':
        final current = playbackState.value.repeatMode;
        final nextRepeat = switch (current) {
          AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
          AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
          AudioServiceRepeatMode.one => AudioServiceRepeatMode.none,
          _ => AudioServiceRepeatMode.none,
        };
        await setRepeatMode(nextRepeat);
        unawaited(_updateWidgetControlsState());
        return true;
      case 'toggle_favorite':
        final updated = await _toggleFavoriteForCurrent();
        if (updated != null) {
          unawaited(_updateWidgetControlsState(isFavoriteOverride: updated));
        }
        return updated ?? false;
      case 'play_index':
        final oneBased = _toInt(extras?['index']) ?? -1;
        if (oneBased > 0) {
          await _ensureQueueLoaded();
          final index = oneBased - 1;
          await skipToQueueItem(index);
          await play();
          final current = mediaItem.value;
          if (current != null) {
            unawaited(_updateWidgetForMediaItem(current));
          }
          return true;
        }
        return true;
      case 'eq_apply':
        final enabled = extras?['enabled'] == true;
        final preampDb = _toDouble(extras?['preampDb']) ?? 0.0;
        final iosModeRaw = extras?['iosMode']?.toString();
        final iosMode = IosEqProcessingMode.values.firstWhere(
          (m) => m.storageKey == iosModeRaw,
          orElse: () => IosEqProcessingMode.tonalSynthesis,
        );
        final bandRaw = extras?['bandGainsDb'];
        final bandMap = <int, double>{};
        if (bandRaw is Map) {
          for (final entry in bandRaw.entries) {
            final key = int.tryParse(entry.key.toString());
            final value = _toDouble(entry.value);
            if (key != null && value != null) {
              bandMap[key] = value;
            }
          }
        }
        await _eqBackend.apply(
          enabled: enabled,
          preampDb: preampDb,
          bandGainsDb: bandMap,
          iosMode: iosMode,
        );
        return true;
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> onTaskRemoved() async {
    await _player.stop();
    await super.onTaskRemoved();
  }

  @override
  Future<void> dispose() async {
    await _eventSub?.cancel();
    await _indexSub?.cancel();
    await _eqBackend.dispose();
    await _player.dispose();
  }

  AudioSource _mediaItemToSource(MediaItem item) {
    final extras = item.extras ?? const <String, dynamic>{};
    final rawUrl = extras['audioUrl']?.toString() ?? item.id;
    final uri = _resolveUri(rawUrl, extras['sourceId']);
    return AudioSource.uri(uri, tag: item);
  }

  Uri _resolveUri(String raw, Object? sourceId) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return Uri();
    if (trimmed.startsWith('content://') ||
        trimmed.startsWith('file://') ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')) {
      return Uri.parse(trimmed);
    }
    if (trimmed.startsWith('/') && sourceId != null) {
      return Uri.parse('content://media/external/audio/media/$sourceId');
    }
    final isWindowsPath = RegExp(r'^[a-zA-Z]:\\').hasMatch(trimmed) ||
        trimmed.startsWith('\\\\');
    if (isWindowsPath) return Uri.file(trimmed);
    if (trimmed.startsWith('/')) return Uri.file(trimmed);
    return Uri.parse(trimmed);
  }

  void _syncMediaItem(int? index) {
    final items = queue.value;
    if (items.isEmpty || index == null) return;
    if (index < 0 || index >= items.length) return;
    mediaItem.add(items[index]);
    unawaited(_updateWidgetForMediaItem(items[index]));
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final processingState = switch (_player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];
    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setSpeed,
          MediaAction.setShuffleMode,
          MediaAction.setRepeatMode,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
    if (playing != _lastWidgetPlaying) {
      _lastWidgetPlaying = playing;
      unawaited(_updateWidgetPlaying(playing));
    }
    final nextRepeat = playbackState.value.repeatMode;
    final nextShuffle = playbackState.value.shuffleMode;
    if (nextRepeat != _lastWidgetRepeatMode ||
        nextShuffle != _lastWidgetShuffleMode) {
      _lastWidgetRepeatMode = nextRepeat;
      _lastWidgetShuffleMode = nextShuffle;
      unawaited(_updateWidgetControlsState());
    }
  }

  Future<void> _maybeRestoreQueue() async {
    if (_restoring) return;
    if (queue.value.isNotEmpty) return;
    _restoring = true;
    try {
      final snapshot = await PlaybackQueueStore.loadSnapshot();
      if (snapshot == null) return;
      await updateQueue(snapshot.items);
      await skipToQueueItem(snapshot.currentIndex);
      if (snapshot.positionMs > 0) {
        await seek(Duration(milliseconds: snapshot.positionMs));
      }
    } catch (e) {
      debugPrint('[AudioHandler] restore queue failed: $e');
    } finally {
      _restoring = false;
    }
  }

  Future<void> _ensureQueueLoaded() async {
    if (queue.value.isNotEmpty) return;
    await _maybeRestoreQueue();
  }

  Future<void> _updateWidgetPlaying(bool playing) async {
    if (!_supportsWidgets) return;
    try {
      await MusicWidgetManager.updatePlayerPlayPause(playing);
    } catch (_) {}
  }

  Future<void> _updateWidgetControlsState({
    bool? isFavoriteOverride,
  }) async {
    if (!_supportsWidgets) return;
    try {
      final isFavorite = isFavoriteOverride ?? await _isCurrentFavorite();
      await MusicWidgetManager.updatePlayerControlsState(
        isShuffled:
            playbackState.value.shuffleMode == AudioServiceShuffleMode.all,
        repeatMode: playbackState.value.repeatMode.index,
        isFavorite: isFavorite,
      );
    } catch (_) {}
  }

  Future<void> _updateWidgetForMediaItem(MediaItem item) async {
    if (!_supportsWidgets) return;
    final music = _musicFromMediaItem(item);
    if (music == null) return;
    unawaited(MusicWidgetManager.setPendingQueueIndex(-1));
    final isFavorite = await _isFavoriteByAudioUrl(music.audioUrl);
    final titles = _queueTitles(limit: 1000);
    final queueCount = queue.value.length;
    final currentIndex = queueCount == 0
        ? 0
        : (_player.currentIndex ?? 0).clamp(0, queueCount - 1);
    await MusicWidgetManager.updatePlayerWidget(
      currentMusic: music.copyWith(isFavorite: isFavorite),
      isPlaying: _player.playing,
      isShuffled:
          playbackState.value.shuffleMode == AudioServiceShuffleMode.all,
      repeatMode: playbackState.value.repeatMode.index,
      isFavorite: isFavorite,
      queueTitles: titles,
      queueCount: queueCount,
      queueStartPosition: 1,
      currentPosition: queueCount == 0 ? 1 : currentIndex + 1,
      totalTracks: queueCount,
    );
  }

  List<String> _queueTitles({int limit = 1000}) {
    final items = queue.value;
    if (items.isEmpty) return const <String>[];
    final list = <String>[];
    for (var i = 0; i < items.length && list.length < limit; i++) {
      list.add(items[i].title);
    }
    return list;
  }

  Future<bool?> _toggleFavoriteForCurrent() async {
    final current = mediaItem.value;
    if (current == null) return null;
    final music = _musicFromMediaItem(current);
    if (music == null) return null;
    final existing = await DatabaseHelper.instance
        .getMusicByAudioUrl(music.audioUrl);
    final nextValue = !(existing?.isFavorite ?? false);
    await DatabaseHelper.instance.toggleFavorite(music.audioUrl, nextValue);
    return nextValue;
  }

  Future<bool> _isCurrentFavorite() async {
    final current = mediaItem.value;
    if (current == null) return false;
    final music = _musicFromMediaItem(current);
    if (music == null) return false;
    return _isFavoriteByAudioUrl(music.audioUrl);
  }

  Future<bool> _isFavoriteByAudioUrl(String audioUrl) async {
    final music = await DatabaseHelper.instance.getMusicByAudioUrl(audioUrl);
    return music?.isFavorite ?? false;
  }

  MusicEntity? _musicFromMediaItem(MediaItem item) {
    final extras = item.extras ?? const <String, dynamic>{};
    final audioUrl = extras['audioUrl']?.toString();
    if (audioUrl == null || audioUrl.isEmpty) return null;
    return MusicEntity(
      id: int.tryParse(item.id),
      sourceId: extras['sourceId'] as int?,
      title: item.title,
      artist: item.artist ?? 'Desconhecido',
      album: item.album,
      artworkUrl: extras['artworkUrl']?.toString(),
      audioUrl: audioUrl,
      duration: item.duration?.inMilliseconds,
      isFavorite: false,
    );
  }

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
