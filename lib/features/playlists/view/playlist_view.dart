import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/features/player/view/mini_player_view.dart';
import 'package:music_music/delegates/music_search_delegate.dart';
import 'package:music_music/data/models/music_entity.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Criar Nova Playlist',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nome da Playlist',
            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                viewModel.createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Criar',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Músicas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
            tooltip: 'Criar nova playlist',
            onPressed: () {
              _showCreatePlaylistDialog(
                context,
                Provider.of<PlaylistViewModel>(context, listen: false),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
            onPressed: () {
              final viewModel = Provider.of<PlaylistViewModel>(
                context,
                listen: false,
              );
              showSearch(
                context: context,
                delegate: MusicSearchDelegate(
                  viewModel.musics, // ✅ MusicEntity direto
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          final List<MusicEntity> musics = viewModel.musics;

          if (musics.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: musics.length,
                  itemBuilder: (context, index) {
                    final music = musics[index];
                    final isPlaying = viewModel.currentMusic?.id == music.id;

                    return Dismissible(
                      key: ValueKey(music.audioUrl),
                      direction: DismissDirection.horizontal,
                      background: _swipeFavoriteBackground(
                        isFavorite: music.isFavorite,
                        theme: theme,
                        isLeft: true,
                      ),
                      secondaryBackground: _swipeFavoriteBackground(
                        isFavorite: music.isFavorite,
                        theme: theme,
                        isLeft: false,
                      ),
                      confirmDismiss: (_) async {
                        HapticFeedback.lightImpact();
                        context.read<PlaylistViewModel>().toggleFavorite(music);
                        return false; // 🔥 não remove da lista
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _animatedMusicTile(
                          context,
                          theme,
                          music,
                          isPlaying,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (viewModel.currentMusic != null) const MiniPlayerView(),
            ],
          );
        },
      ),
    );
  }

  Widget _swipeFavoriteBackground({
  required bool isFavorite,
  required ThemeData theme,
  required bool isLeft,
}) {
  return Container(
    alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: isFavorite
          ? Colors.grey.shade800
          : Colors.redAccent,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Icon(
      isFavorite ? Icons.favorite_border : Icons.favorite,
      color: Colors.white,
      size: 30,
    ),
  );
}
Widget _animatedMusicTile(
  BuildContext context,
  ThemeData theme,
  MusicEntity music,
  bool isPlaying,
) {
  return AnimatedScale(
    scale: music.isFavorite ? 1.0 : 0.97,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
    child: AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 200),
      child: _musicTile(context, theme, music, isPlaying),
    ),
  );
}

Widget _musicTile(
  BuildContext context,
  ThemeData theme,
  MusicEntity music,
  bool isPlaying,
) {
  return Container(
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(15),
      border: isPlaying
          ? Border.all(color: theme.colorScheme.primary, width: 2)
          : null,
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ListTile(
      leading: Icon(Icons.music_note),
      title: Text(music.title),
      subtitle: Text(music.artist),
      onTap: () {
        context.read<PlaylistViewModel>().playMusic(
              context.read<PlaylistViewModel>().musics,
              context.read<PlaylistViewModel>().musics.indexOf(music),
            );
      },
    ),
  );
}


}



