import 'package:flutter/material.dart';
import 'package:music_music/core/ui/TextSpan_highlight.dart';
import 'package:music_music/data/models/search_result.dart';
import 'package:music_music/features/library/view/artist_detail_screen.dart';
import 'package:music_music/features/player/view/player_view.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:provider/provider.dart';

class SearchResultsView extends StatelessWidget {
  final List<SearchResult> results;
  final String query;

  final void Function(SearchResult result) onTap;

  const SearchResultsView({
    super.key,
    required this.results,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _SearchSections.from(results);

    final style = Theme.of(context).textTheme.bodyLarge!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (sections.musics.isNotEmpty) ...[
          _SectionTitle('Músicas'),
          ...sections.musics.map(
            (r) => ListTile(
              leading: const Icon(Icons.music_note),
              title: RichText(text: highlight(r.title, query, style)),
               onTap: () => onTap(r),
            ),
          ),
        ],

        if (sections.artists.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('Artistas'),
          ...sections.artists.map(
            (r) => ListTile(
              leading: const Icon(Icons.person),
              title: RichText(text: highlight(r.title, query, style)),
               onTap: () => onTap(r),
            ),
          ),
        ],

        if (sections.albums.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('Álbuns'),
          ...sections.albums.map(
            (r) => ListTile(
              leading: const Icon(Icons.album),
              title: RichText(text: highlight(r.title, query, style)),
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchSections {
  final List<SearchResult> musics;
  final List<SearchResult> artists;
  final List<SearchResult> albums;

  const _SearchSections({
    required this.musics,
    required this.artists,
    required this.albums,
  });

  static _SearchSections from(List<SearchResult> results) {
    final musics = <SearchResult>[];
    final artists = <SearchResult>[];
    final albums = <SearchResult>[];

    for (final r in results) {
      switch (r.type) {
        case SearchType.music:
          musics.add(r);
          break;
        case SearchType.artist:
          artists.add(r);
          break;
        case SearchType.album:
          albums.add(r);
          break;
      }
    }

    return _SearchSections(
      musics: musics,
      artists: artists,
      albums: albums,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

