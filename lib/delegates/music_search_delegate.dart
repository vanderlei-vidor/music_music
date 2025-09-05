import 'package:flutter/material.dart';
import 'package:music_music/models/music_model.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_colors.dart';

class MusicSearchDelegate extends SearchDelegate<String> {
  final List<Music> allMusics;

  MusicSearchDelegate(this.allMusics);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        color: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        labelStyle: TextStyle(color: Colors.white),
        border: InputBorder.none,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
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
        return ListTile(
          leading: QueryArtworkWidget(
            id: music.albumId ?? 0,
            type: ArtworkType.ALBUM,
            artworkBorder: BorderRadius.circular(10),
            nullArtworkWidget: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.music_note, color: Colors.white),
            ),
          ),
          title: Text(
            music.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            music.artist ?? "Artista desconhecido",
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          onTap: () {
            // Ação ao tocar na música para reproduzi-la
            // Você pode querer chamar um método do ViewModel aqui para iniciar a reprodução.
            // Por exemplo: Provider.of<PlaylistViewModel>(context, listen: false).playMusic(musics, index);
            close(context, ''); // Fecha a tela de busca
          },
        );
      },
    );
  }
}