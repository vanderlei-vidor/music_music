import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:music_music/features/podcasts/data/podcast_item.dart';

class PodcastRepository {
  Future<List<PodcastItem>> fetchTrendingPodcasts({
    String term = 'technology',
    int limit = 20,
  }) async {
    final encodedTerm = Uri.encodeComponent(term);
    final url =
        'https://itunes.apple.com/search?media=podcast&entity=podcast&term=$encodedTerm&limit=$limit';

    try {
      final payload = await NetworkAssetBundle(Uri.parse(url)).loadString('');
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final results = (decoded['results'] as List<dynamic>? ?? const []);

      final unique = <int, PodcastItem>{};
      for (final raw in results) {
        if (raw is! Map<String, dynamic>) continue;
        final id = raw['collectionId'];
        if (id is! int) continue;

        unique[id] = PodcastItem(
          id: id,
          title: (raw['collectionName'] as String?)?.trim().isNotEmpty == true
              ? raw['collectionName'] as String
              : 'Podcast',
          author: (raw['artistName'] as String?)?.trim().isNotEmpty == true
              ? raw['artistName'] as String
              : 'Autor desconhecido',
          artworkUrl: (raw['artworkUrl600'] as String?) ??
              (raw['artworkUrl100'] as String?) ??
              '',
          feedUrl: raw['feedUrl'] as String?,
          episodeCount: (raw['trackCount'] as int?) ?? 0,
          genre: (raw['primaryGenreName'] as String?) ?? 'Podcast',
        );
      }

      final items = unique.values.toList();
      if (items.isNotEmpty) return items;
    } catch (_) {
      // Fallback local when network is unavailable or blocked.
    }

    return _fallbackPodcasts;
  }
}

const List<PodcastItem> _fallbackPodcasts = [
  PodcastItem(
    id: 1,
    title: 'Syntax',
    author: 'Wes Bos & Scott Tolinski',
    artworkUrl:
        'https://is1-ssl.mzstatic.com/image/thumb/Podcasts112/v4/5a/83/93/5a839307-3ea0-c023-9715-20c95e4f3436/mza_12639615380358624995.jpg/600x600bb.jpg',
    feedUrl: null,
    episodeCount: 0,
    genre: 'Technology',
  ),
  PodcastItem(
    id: 2,
    title: 'The Changelog',
    author: 'Changelog Media',
    artworkUrl:
        'https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/18/3a/d4/183ad4b1-a932-d470-f331-5efa5db3db1f/mza_10971637866922287171.jpg/600x600bb.jpg',
    feedUrl: null,
    episodeCount: 0,
    genre: 'Technology',
  ),
  PodcastItem(
    id: 3,
    title: 'Acquired',
    author: 'Ben Gilbert and David Rosenthal',
    artworkUrl:
        'https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/e4/4f/cc/e44fcc27-9e52-f2e1-01fe-cf4ef95b0d37/mza_6571603607653952235.jpg/600x600bb.jpg',
    feedUrl: null,
    episodeCount: 0,
    genre: 'Business',
  ),
];
