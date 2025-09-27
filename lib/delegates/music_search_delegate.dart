import 'package:flutter/material.dart';
import 'package:music_music/models/music_model.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_colors.dart';



class MusicSearchDelegate extends SearchDelegate<String> {
  final List<Music> allMusics;

  MusicSearchDelegate(this.allMusics);

  @override
  ThemeData appBarTheme(BuildContext context) {
  final theme = Theme.of(context);
  return theme.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Usa a cor do tema atual
      elevation: 0,
      iconTheme: IconThemeData(color: theme.colorScheme.onBackground),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: theme.hintColor),
      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
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
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = allMusics.where(
      (music) => music.title.toLowerCase().contains(query.toLowerCase()) ||
                 (music.artist != null && music.artist!.toLowerCase().contains(query.toLowerCase())),
    ).toList();

    return _buildMusicList(results, context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = allMusics.where(
      (music) => music.title.toLowerCase().contains(query.toLowerCase()) ||
                 (music.artist != null && music.artist!.toLowerCase().contains(query.toLowerCase())),
    ).toList();
    
    return _buildMusicList(suggestions, context);
  }

  Widget _buildMusicList(List<Music> musics, BuildContext context) {
    if (musics.isEmpty) {
      return const Center(
        child: Text(
          "Nenhuma música encontrada.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return ListView.builder(
  itemCount: musics.length,
  itemBuilder: (context, index) {
    final music = musics[index];
    final theme = Theme.of(context); // 👈 Pega o tema atual

    return ListTile(
      leading: QueryArtworkWidget(
        id: music.albumId ?? 0,
        type: ArtworkType.ALBUM,
        artworkBorder: BorderRadius.circular(10),
        nullArtworkWidget: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary, // ✅ Usa a cor primária do tema atual
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.music_note,
            color: theme.colorScheme.onPrimary, // ✅ Cor do ícone sobre fundo primário
          ),
        ),
      ),
      title: Text(
        music.title,
        style: TextStyle(
          color: theme.colorScheme.onSurface, // ✅ Cor do texto principal
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        music.artist ?? "Artista desconhecido",
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.7), // ✅ Cor secundária suave
        ),
      ),
      onTap: () {
        close(context, '');
      },
    );
  },
);
  }
}