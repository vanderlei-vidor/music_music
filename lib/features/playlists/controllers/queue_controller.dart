import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_music/data/models/music_entity.dart';

class QueueController {
  QueueController({required int Function() rawQueueIndex})
      : _rawQueueIndex = rawQueueIndex;

  final int Function() _rawQueueIndex;

  List<MusicEntity> _queue = <MusicEntity>[];
  bool _isShuffled = false;
  LoopMode _repeatMode = LoopMode.off;

  List<MusicEntity> get queue => _queue;
  set queue(List<MusicEntity> value) {
    _queue = value;
  }

  bool get isShuffled => _isShuffled;
  set isShuffled(bool value) {
    _isShuffled = value;
  }

  LoopMode get repeatMode => _repeatMode;
  set repeatMode(LoopMode value) {
    _repeatMode = value;
  }

  int get currentIndex {
    final idx = _rawQueueIndex();
    if (_queue.isEmpty) return 0;
    return idx.clamp(0, _queue.length - 1);
  }

  int get queueCount => _queue.length;

  int currentPosition() {
    if (_queue.isEmpty) return 1;
    return currentIndex + 1;
  }

  List<String> titles({int limit = 1000}) {
    if (_queue.isEmpty) return const <String>[];
    final list = <String>[];
    for (var i = 0; i < _queue.length && list.length < limit; i++) {
      list.add(_queue[i].title);
    }
    return list;
  }

  int indexOfAudioUrl(String audioUrl) {
    return _queue.indexWhere((m) => m.audioUrl == audioUrl);
  }

  bool replaceByAudioUrl(MusicEntity updated) {
    final idx = indexOfAudioUrl(updated.audioUrl);
    if (idx == -1) return false;
    _queue[idx] = updated;
    return true;
  }

  bool replaceIfDifferent(List<MusicEntity> nextQueue) {
    final same = listEquals(
      _queue.map((e) => e.audioUrl).toList(),
      nextQueue.map((e) => e.audioUrl).toList(),
    );
    if (same) return false;
    _queue = List<MusicEntity>.from(nextQueue);
    return true;
  }

  int reorder({
    required int oldIndex,
    required int newIndex,
    int? currentMusicId,
  }) {
    if (_queue.isEmpty) return 0;
    if (oldIndex < 0 || oldIndex >= _queue.length) return currentIndex;
    if (newIndex < 0 || newIndex > _queue.length) return currentIndex;

    final targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    final moved = _queue.removeAt(oldIndex);
    _queue.insert(targetIndex, moved);

    if (currentMusicId != null) {
      final idx = _queue.indexWhere((m) => m.id == currentMusicId);
      return idx == -1 ? 0 : idx;
    }
    return targetIndex.clamp(0, _queue.length - 1);
  }
}
