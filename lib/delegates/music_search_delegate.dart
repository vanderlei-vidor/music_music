import 'package:flutter/material.dart';
import 'package:music_music/data/models/music_entity.dart';

class MusicSearchDelegate extends SearchDelegate<String> {
  final List<MusicEntity> allMusics;

  MusicSearchDelegate(this.allMusics);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: theme.hintColor),
        border: InputBorder.none,
      ),
      scaffoldBackgroundColor: theme.scaffoldBackgroundColor,
      textTheme: theme.textTheme.copyWith(
        titleLarge: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filterMusics();
    return _buildMusicList(results, context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _filterMusics();
    return _buildMusicList(suggestions, context);
  }

  List<MusicEntity> _filterMusics() {
    final q = query.toLowerCase();
    return allMusics.where((music) {
      return music.title.toLowerCase().contains(q) ||
          music.artist.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildMusicList(
    List<MusicEntity> musics,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    if (musics.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma mÃºsica encontrada.',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: musics.length,
      itemBuilder: (context, index) {
        final music = musics[index];

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: music.artworkUrl != null
                ? Image.network(
                    music.artworkUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _defaultArtwork(theme),
                  )
                : _defaultArtwork(theme),
          ),
          title: Text(
            music.title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            music.artist,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          onTap: () {
            close(context, music.id.toString());
          },
        );
      },
    );
  }

  Widget _defaultArtwork(ThemeData theme) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.music_note,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }
}


