// lib/views/player/mini_player_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
// Remova esta linha, pois não vamos usar AppColors diretamente:
// import '../../core/theme/app_colors.dart'; 
import '../playlist/playlist_view_model.dart';
import 'player_view.dart';

class MiniPlayerView extends StatelessWidget {
  const MiniPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 👈 Pega o tema atual

    return Consumer<PlaylistViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.currentMusic == null) {
          return const SizedBox.shrink();
        }

        final currentMusic = viewModel.currentMusic!;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerView()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor, // ✅ Usa a cor do card do tema atual
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.3), // ✅ Sombra adaptável
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Arte do álbum
                QueryArtworkWidget(
                  id: currentMusic.albumId ?? 0,
                  type: ArtworkType.ALBUM,
                  artworkBorder: BorderRadius.circular(10),
                  nullArtworkWidget: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary, // ✅ Cor primária do tema
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: theme.colorScheme.onPrimary, // ✅ Cor sobre fundo primário
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Título e artista
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentMusic.title,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface, // ✅ Texto legível
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentMusic.artist ?? "Artista desconhecido",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7), // ✅ Secundário
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Botão de play/pause
                IconButton(
                  icon: Icon(
                    viewModel.playerState == PlayerState.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: theme.colorScheme.primary, // ✅ Usa a cor primária (roxa)
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