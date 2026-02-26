class PodcastItem {
  final int id;
  final String title;
  final String author;
  final String artworkUrl;
  final String? feedUrl;
  final int episodeCount;
  final String genre;

  const PodcastItem({
    required this.id,
    required this.title,
    required this.author,
    required this.artworkUrl,
    required this.feedUrl,
    required this.episodeCount,
    required this.genre,
  });
}
