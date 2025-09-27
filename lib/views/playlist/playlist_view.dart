// lib/views/playlist/playlist_view.dart

import 'package:flutter/material.dart';
import 'package:music_music/delegates/music_search_delegate.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
// Remova esta linha:
// import '../../core/theme/app_colors.dart';
import 'playlist_view_model.dart';
import '../player/player_view.dart';
import '../player/mini_player_view.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState; // 👈 necessário para PlayerState

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  String _formatDuration(int? duration) {
    if (duration == null) return "00:00";
    final minutes = (duration / 60000).truncate();
    final seconds = ((duration % 60000) / 1000).truncate();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showCreatePlaylistDialog(BuildContext context, PlaylistViewModel viewModel) {
  final theme = Theme.of(context);
  final TextEditingController controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text('Criar Nova Playlist', style: TextStyle(color: theme.colorScheme.onSurface)),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Nome da Playlist',
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
        ),
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.onSurface)),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              viewModel.createPlaylist(controller.text);
              Navigator.pop(context);
            }
          },
          child: Text('Criar', style: TextStyle(color: theme.colorScheme.primary)),
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
          'Minha Playlist',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
    // ✅ Botão de CRIAR NOVA PLAYLIST
    IconButton(
      icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
      tooltip: 'Criar nova playlist',
      onPressed: () {
        _showCreatePlaylistDialog(context, Provider.of<PlaylistViewModel>(context, listen: false));
        
      },
    ),
    // ✅ Botão de busca
    IconButton(
      icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
      onPressed: () {
        final viewModel = Provider.of<PlaylistViewModel>(context, listen: false);
        showSearch(
          context: context,
          delegate: MusicSearchDelegate(viewModel.musics),
        );
      },
    ),
  ],
      ),
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          final musics = viewModel.musics;
          if (musics == null || musics.isEmpty) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: musics.length,
                  itemBuilder: (context, index) {
                    final music = musics[index];
                    final isPlaying = viewModel.currentMusic?.id == music.id;
                    final theme = Theme.of(context); // 👈 tema dentro do builder

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
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
                          leading: QueryArtworkWidget(
                            id: music.albumId ?? 0,
                            type: ArtworkType.ALBUM,
                            artworkBorder: BorderRadius.circular(10),
                            nullArtworkWidget: Container(
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
                            ),
                          ),
                          title: Text(
                            music.title,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            music.artist ?? "Artista desconhecido",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          trailing: isPlaying
                              ? StreamBuilder<Duration>(
                                  stream: viewModel.positionStream,
                                  builder: (context, snapshot) {
                                    final position = snapshot.data ?? Duration.zero;
                                    final totalDuration = Duration(milliseconds: music.duration ?? 0);
                                    final progress = totalDuration.inMilliseconds > 0
                                        ? position.inMilliseconds / totalDuration.inMilliseconds
                                        : 0.0;

                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            viewModel.playerState == PlayerState.playing
                                                ? Icons.pause_circle_filled
                                                : Icons.play_circle_filled,
                                            color: theme.colorScheme.primary,
                                            size: 40,
                                          ),
                                          onPressed: viewModel.playPause,
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : Text(
                                  _formatDuration(music.duration),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                          onTap: () {
                            if (isPlaying) {
                              viewModel.playPause();
                            } else {
                              viewModel.playMusic(musics, index);
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PlayerView()),
                            );
                          },
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
}