import 'package:music_music/data/models/music_entity.dart';

class PodcastDetector {
  static final int _veryLongAudioMs = const Duration(minutes: 45).inMilliseconds;
  static final int _longAudioMs = const Duration(minutes: 25).inMilliseconds;
  static const String mediaTypePodcast = 'podcast';
  static const String mediaTypeMusic = 'music';

  static const _audioExtensions = <String>{
    '.mp3',
    '.m4a',
    '.aac',
    '.ogg',
    '.wav',
    '.flac',
    '.opus',
    '.wma',
    '.amr',
    '.aiff',
    '.alac',
  };

  static const _videoExtensions = <String>{
    '.mp4',
    '.mkv',
    '.webm',
    '.avi',
    '.mov',
    '.wmv',
    '.m4v',
    '.3gp',
    '.flv',
    '.mpeg',
    '.mpg',
  };

  static const _genreKeywords = <String>[
    'podcast',
    'audiobook',
    'spoken word',
    'talk',
    'news',
  ];

  static const _titleKeywords = <String>[
    'podcast',
    'episode',
    'ep.',
    'ep ',
    'interview',
    'talk',
  ];

  static bool looksLikePodcast(MusicEntity music) {
    if (!_isAudioFile(music.audioUrl)) return false;

    final genre = (music.genre ?? '').toLowerCase();
    final title = music.title.toLowerCase();
    final album = (music.album ?? '').toLowerCase();
    final artist = music.artist.toLowerCase();
    final folder = (music.folderPath ?? '').toLowerCase();
    final durationMs = normalizeDurationToMs(music.duration ?? 0);

    final genreHit = _genreKeywords.any(genre.contains);
    if (genreHit) return true;

    final titleHit = _titleKeywords.any(title.contains);
    final albumHit = _titleKeywords.any(album.contains);
    final folderHit = _titleKeywords.any(folder.contains);
    final longForm = durationMs >= _longAudioMs;
    final veryLongForm = durationMs >= _veryLongAudioMs;
    final spokenProfile = artist.contains('podcast') || artist.contains('radio');

    // Very long audio is usually podcast/audiobook in local libraries.
    if (veryLongForm) return true;

    if (folderHit && longForm) return true;
    if (longForm && (titleHit || albumHit || spokenProfile)) return true;
    return false;
  }

  static bool isPodcast(MusicEntity music) {
    final type = (music.mediaType ?? '').toLowerCase();
    if (type == mediaTypePodcast) return true;
    if (type == mediaTypeMusic) return false;

    final genre = (music.genre ?? '').toLowerCase();
    if (genre.contains('podcast')) return true;
    return looksLikePodcast(music);
  }

  static MusicEntity normalizeGenre(MusicEntity music) {
    if (!looksLikePodcast(music)) return music;
    return music.copyWith(genre: 'Podcast');
  }

  static MusicEntity normalizeMediaType(MusicEntity music) {
    if (music.mediaType != null && music.mediaType!.isNotEmpty) return music;
    return music.copyWith(
      mediaType: looksLikePodcast(music) ? mediaTypePodcast : mediaTypeMusic,
    );
  }

  static bool _isAudioFile(String url) {
    final clean = url.toLowerCase().split('?').first.split('#').first;

    // Android MediaStore audio URIs usually come as:
    // content://media/.../audio/...
    if (clean.startsWith('content://') && clean.contains('/audio/')) {
      return true;
    }

    for (final ext in _videoExtensions) {
      if (clean.endsWith(ext)) return false;
    }
    for (final ext in _audioExtensions) {
      if (clean.endsWith(ext)) return true;
    }

    if (clean.startsWith('content://')) {
      return true;
    }

    // If extension is unknown, keep conservative behavior and do not classify.
    return false;
  }

  static int normalizeDurationToMs(int raw) {
    if (raw <= 0) return 0;
    // Some providers may return seconds; treat very small values as seconds.
    if (raw < 100000) return raw * 1000;
    return raw;
  }
}
