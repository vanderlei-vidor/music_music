import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_colors.dart';
import '../playlist/playlist_view_model.dart';
// Removida a importação de 'package:just_audio/just_audio.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          final music = viewModel.currentMusic;
          if (music == null) {
            return const Center(child: Text('Nenhuma música sendo tocada.'));
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, Color(0xFF13101E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botão de voltar
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Imagem do álbum - Agora com tamanho uniforme
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.width * 0.9,
                    child: QueryArtworkWidget(
                      id: music.albumId ?? 0,
                      type: ArtworkType.ALBUM,
                      artworkBorder: BorderRadius.circular(20),
                      nullArtworkWidget: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.music_note, size: 100, color: AppColors.lightPurple),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Título e Artista
                  // Título com rolagem horizontal para nomes longos
                  SizedBox(
                    height: 30, // Altura para o texto
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        music.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible, // Permite que o texto saia da caixa
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    music.artist, // Tratamento para artista nulo
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 30),

                  // Barra de progresso e tempos com Slider
                  StreamBuilder<Duration>(
                    stream: viewModel.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final totalDuration = Duration(milliseconds: music.duration ?? 0);
                      
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                              activeTrackColor: AppColors.accentPurple,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: AppColors.accentPurple,
                              overlayColor: AppColors.accentPurple.withOpacity(0.2),
                            ),
                            child: Slider(
                              value: position.inMilliseconds.toDouble(),
                              min: 0.0,
                              max: totalDuration.inMilliseconds.toDouble(),
                              onChanged: (double value) {
                                // Pode ser usado para pré-visualização, se necessário
                              },
                              onChangeEnd: (double value) {
                                viewModel.seek(Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                _formatDuration(totalDuration),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Controles do player
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white),
                        onPressed: viewModel.previousMusic,
                      ),
                      const SizedBox(width: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            viewModel.playerState == PlayerState.playing ? Icons.pause : Icons.play_arrow,
                            size: 40,
                          ),
                          color: Colors.white,
                          onPressed: viewModel.playPause,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
                        onPressed: viewModel.nextMusic,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
