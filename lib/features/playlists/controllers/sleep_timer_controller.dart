import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:music_music/features/playlists/models/sleep_timer_mode.dart';

class SleepTimerController {
  SleepTimerController({
    required Future<void> Function() onExpire,
    required VoidCallback onNotify,
    required bool Function() isPlaying,
    required Duration Function() currentPosition,
    required int? Function() currentTrackDurationMs,
    required List<int?> Function() queueDurationsMs,
    required int Function() currentIndex,
  })  : _onExpire = onExpire,
        _onNotify = onNotify,
        _isPlaying = isPlaying,
        _currentPosition = currentPosition,
        _currentTrackDurationMs = currentTrackDurationMs,
        _queueDurationsMs = queueDurationsMs,
        _currentIndex = currentIndex;

  final Future<void> Function() _onExpire;
  final VoidCallback _onNotify;
  final bool Function() _isPlaying;
  final Duration Function() _currentPosition;
  final int? Function() _currentTrackDurationMs;
  final List<int?> Function() _queueDurationsMs;
  final int Function() _currentIndex;

  SleepTimerMode _mode = SleepTimerMode.off;
  Duration? _duration;
  DateTime? _endTime;
  Duration? _pausedRemaining;
  Timer? _sleepTimer;
  Timer? _sleepTick;
  int _lastEndOfSongSecond = -1;

  SleepTimerMode get mode => _mode;
  Duration? get duration => _duration;
  DateTime? get endTime => _endTime;
  bool get hasActiveTimer => _sleepTimer?.isActive ?? false;
  Duration? get remaining {
    if (_endTime == null) return null;
    final left = _endTime!.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void setSleepTimer(Duration duration) {
    _mode = SleepTimerMode.duration;
    _duration = duration;
    _startSleepCountdown(duration, force: true);
  }

  void cancel() {
    _clearSleepTimer();
  }

  void setEndOfSong() {
    _mode = SleepTimerMode.endOfSong;
    _duration = null;
    _syncEndOfSongTimer();
  }

  void setEndOfPlaylist() {
    _mode = SleepTimerMode.endOfPlaylist;
    _duration = null;
    _syncEndOfPlaylistTimer();
  }

  void handlePlayingChanged(bool playing) {
    if (!playing) {
      _pauseSleepTimer();
    } else {
      _resumeSleepTimerIfNeeded();
    }
  }

  void handlePlaybackCompleted() {
    if (_mode == SleepTimerMode.endOfPlaylist) {
      _clearSleepTimer();
    }
  }

  void handlePosition(Duration position) {
    if (_mode == SleepTimerMode.endOfSong) {
      if (position.inSeconds != _lastEndOfSongSecond) {
        _lastEndOfSongSecond = position.inSeconds;
        _syncEndOfSongTimer(position: position);
      }
    } else if (_mode == SleepTimerMode.endOfPlaylist) {
      _syncEndOfPlaylistTimer(position: position);
    }
  }

  void handleTrackChanged() {
    _lastEndOfSongSecond = -1;
    if (_mode == SleepTimerMode.endOfSong) {
      _syncEndOfSongTimer();
    } else if (_mode == SleepTimerMode.endOfPlaylist) {
      _syncEndOfPlaylistTimer();
    }
  }

  void dispose() {
    _sleepTimer?.cancel();
    _sleepTick?.cancel();
    _sleepTimer = null;
    _sleepTick = null;
  }

  void _startSleepCountdown(Duration remaining, {bool force = true}) {
    if (!_isPlaying()) {
      _pausedRemaining = remaining;
      _onNotify();
      return;
    }

    final newEndTime = DateTime.now().add(remaining);
    if (!force && _endTime != null && _sleepTimer?.isActive == true) {
      final delta = _endTime!.difference(newEndTime).abs();
      if (delta < const Duration(seconds: 2)) {
        return;
      }
    }

    _sleepTimer?.cancel();
    _sleepTick?.cancel();

    _endTime = newEndTime;
    _onNotify();

    _sleepTimer = Timer(remaining, () async {
      await _onExpire();
      _clearSleepTimer();
    });

    _sleepTick = Timer.periodic(const Duration(seconds: 1), (_) {
      _onNotify();
    });
  }

  void _clearSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTick?.cancel();
    _sleepTimer = null;
    _sleepTick = null;
    _duration = null;
    _endTime = null;
    _mode = SleepTimerMode.off;
    _pausedRemaining = null;
    _onNotify();
  }

  void _pauseSleepTimer() {
    if (_sleepTimer == null || _endTime == null) return;

    final remaining = _endTime!.difference(DateTime.now());
    _pausedRemaining = remaining.isNegative ? Duration.zero : remaining;
    _sleepTimer?.cancel();
    _sleepTick?.cancel();
    _sleepTimer = null;
    _sleepTick = null;
    _onNotify();
  }

  void _resumeSleepTimerIfNeeded() {
    if (_mode == SleepTimerMode.off) return;

    if (_mode == SleepTimerMode.duration) {
      if (_pausedRemaining != null) {
        _startSleepCountdown(_pausedRemaining!, force: true);
        _pausedRemaining = null;
      }
      return;
    }

    if (_mode == SleepTimerMode.endOfSong) {
      _syncEndOfSongTimer();
      return;
    }

    if (_mode == SleepTimerMode.endOfPlaylist) {
      _syncEndOfPlaylistTimer();
    }
  }

  void _syncEndOfSongTimer({Duration? position}) {
    final durationMs = _currentTrackDurationMs() ?? 0;
    if (durationMs <= 0) return;

    final pos = position ?? _currentPosition();
    final remainingMs = (durationMs - pos.inMilliseconds).clamp(0, durationMs);
    _startSleepCountdown(Duration(milliseconds: remainingMs), force: false);
  }

  void _syncEndOfPlaylistTimer({Duration? position}) {
    final durations = _queueDurationsMs();
    if (durations.isEmpty) return;
    final index = _currentIndex();
    if (index < 0 || index >= durations.length) return;

    final pos = position ?? _currentPosition();
    final currentMs = durations[index] ?? 0;
    if (currentMs <= 0) return;

    var remainingMs = (currentMs - pos.inMilliseconds).clamp(0, currentMs);
    for (var i = index + 1; i < durations.length; i++) {
      remainingMs += durations[i] ?? 0;
    }

    _startSleepCountdown(Duration(milliseconds: remainingMs), force: false);
  }
}
