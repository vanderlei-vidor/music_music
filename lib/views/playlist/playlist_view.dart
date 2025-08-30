import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_colors.dart';
import 'playlist_view_model.dart';
import '../player/player_view.dart';
import '../player/mini_player_view.dart'; // Importação do mini-player

class PlaylistView extends StatelessWidget {
  const PlaylistView({super.key});

  String _formatDuration(int? duration) {
    if (duration == null) return "00:00";
    final minutes = (duration / 60000).truncate();
    final seconds = ((duration % 60000) / 1000).truncate();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Ação do botão de busca
            },
          ),
        ],
      ),
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          final musics = viewModel.musics;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: musics.length,
                  itemBuilder: (context, index) {
                    final music = musics[index];
                    final isPlaying = viewModel.currentMusic?.id == music.id;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(15),
                          border: isPlaying ? Border.all(color: AppColors.accentPurple, width: 2) : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
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
                            music.artist,
                            style: const TextStyle(
                              color: Colors.white70,
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
                                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                                            backgroundColor: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            viewModel.playerState == PlayerState.playing
                                                ? Icons.pause_circle_filled
                                                : Icons.play_circle_filled,
                                            color: AppColors.accentPurple,
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
                                  style: const TextStyle(color: Colors.white70),
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
              // Adicionando o mini player na parte inferior
              if (viewModel.currentMusic != null)
                const MiniPlayerView(),
            ],
          );
        },
      ),
    );
  }
}
