import 'dart:collection';
import 'package:flutter/material.dart';

class ArtworkCache {
  static final LinkedHashMap<String, ImageProvider> _cache = LinkedHashMap();
  static const int _maxEntries = 200;
  static int _maxEntriesOverride = _maxEntries;

  static ImageProvider? provider(String? url) {
    if (url == null || url.isEmpty) return null;
    final existing = _cache.remove(url);
    if (existing != null) {
      _cache[url] = existing;
      return existing;
    }
    final created = NetworkImage(url);
    _cache[url] = created;
    if (_cache.length > _maxEntriesOverride) {
      _cache.remove(_cache.keys.first);
    }
    return created;
  }

  static void preload(BuildContext context, String? url) {
    final image = provider(url);
    if (image == null) return;
    precacheImage(image, context);
  }

  static void configure({int? maxEntries}) {
    if (maxEntries != null && maxEntries > 50) {
      _maxEntriesOverride = maxEntries;
    }
  }

  static void clear() {
    _cache.clear();
  }
}

class ArtworkThumb extends StatelessWidget {
  final String? artworkUrl;

  const ArtworkThumb({super.key, required this.artworkUrl});

  @override
  Widget build(BuildContext context) {
    final provider = ArtworkCache.provider(artworkUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: provider != null
            ? Image(
                image: provider,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const _ArtworkFallback(),
              )
            : const _ArtworkFallback(),
      ),
    );
  }
}

class ArtworkSquare extends StatelessWidget {
  final String? artworkUrl;
  final double borderRadius;

  const ArtworkSquare({
    super.key,
    required this.artworkUrl,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final provider = ArtworkCache.provider(artworkUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: provider != null
          ? Image(
              image: provider,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const _ArtworkFallback(),
            )
          : const _ArtworkFallback(),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.35),
            theme.colorScheme.secondary.withOpacity(0.35),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white70,
      ),
    );
  }
}
