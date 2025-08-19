// lib/views/player/mini_player_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_colors.dart';
import '../playlist/playlist_view_model.dart';
import 'player_view.dart';

class MiniPlayerView extends StatelessWidget {
  const MiniPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.currentMusic == null) {
          return const SizedBox.shrink(); // Não exibe nada se não houver música tocando
        }
        
        final currentMusic = viewModel.currentMusic!;

        return GestureDetector(
          onTap: () {
            // Navega para a tela do player de tela cheia
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerView()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Arte do álbum da música
                QueryArtworkWidget(
                  id: currentMusic.albumId ?? 0,
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
                const SizedBox(width: 12),
                // Título e artista da música
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentMusic.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentMusic.artist,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Controles de reprodução (play/pause)
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
            ),
          ),
        );
      },
    );
  }
}
