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
    final musics = results.where((r) => r.type == SearchType.music).toList();
    final artists = results.where((r) => r.type == SearchType.artist).toList();
    final albums = results.where((r) => r.type == SearchType.album).toList();

    final style = Theme.of(context).textTheme.bodyLarge!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (musics.isNotEmpty) ...[
          _SectionTitle('Músicas'),
          ...musics.map(
            (r) => ListTile(
              leading: const Icon(Icons.music_note),
              title: RichText(text: highlight(r.title, query, style)),
               onTap: () => onTap(r),
            ),
          ),
        ],

        if (artists.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('Artistas'),
          ...artists.map(
            (r) => ListTile(
              leading: const Icon(Icons.person),
              title: RichText(text: highlight(r.title, query, style)),
               onTap: () => onTap(r),
            ),
          ),
        ],

        if (albums.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('Álbuns'),
          ...albums.map(
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

