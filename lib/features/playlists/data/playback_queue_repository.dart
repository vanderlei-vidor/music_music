abstract class PlaybackQueueRepository {
  Future<Map<String, dynamic>?> loadPlaybackQueue();

  Future<void> savePlaybackQueue({
    required List<String> audioUrls,
    required int currentIndex,
    required int positionMs,
  });

  Future<void> clearPlaybackQueue();
}
