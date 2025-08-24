// lib/views/player/player_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../../core/theme/app_colors.dart';
import '../playlist/playlist_view_model.dart';
import '../../widgets/sleep_timer_button.dart'; // Importação do novo widget

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Função auxiliar para determinar a cor do botão de repetição
  Color _getRepeatButtonColor(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return Colors.white70;
      case LoopMode.one:
      case LoopMode.all:
        return AppColors.accentPurple;
    }
  }

  // Função auxiliar para determinar o ícone do botão de repetição
  IconData _getRepeatButtonIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
      case LoopMode.all:
        return Icons.repeat;
      case LoopMode.one:
        return Icons.repeat_one;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Deixa a AppBar transparente
        elevation: 0, // Remove a sombra
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          SleepTimerButton(),
        ],
      ),
      extendBodyBehindAppBar: true, // Permite que o corpo se estenda por trás da AppBar
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          final music = viewModel.currentMusic;
          if (music == null) {
            return const Center(child: Text('Nenhuma música sendo tocada.'));
          }
          final List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

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
                  // Removeremos o Align com o IconButton e usaremos a AppBar
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
                  SizedBox(
                    height: 30,
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
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    music.artist,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 30),
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
                              value: totalDuration.inMilliseconds > 0
                                  ? position.inMilliseconds.toDouble()
                                  : 0.0,
                              min: 0.0,
                              max: totalDuration.inMilliseconds.toDouble(),
                              onChanged: (double value) {},
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.shuffle,
                          size: 28,
                          color: viewModel.isShuffled ? AppColors.accentPurple : Colors.white70,
                        ),
                        onPressed: viewModel.toggleShuffle,
                      ),
                      const SizedBox(width: 20),
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
                            color: Colors.white,
                          ),
                          onPressed: viewModel.playPause,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
                        onPressed: viewModel.nextMusic,
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Icon(
                          _getRepeatButtonIcon(viewModel.repeatMode),
                          size: 28,
                          color: _getRepeatButtonColor(viewModel.repeatMode),
                        ),
                        onPressed: viewModel.toggleRepeatMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  DropdownButton<double>(
                    value: viewModel.currentSpeed,
                    dropdownColor: AppColors.cardBackground,
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.speed, color: AppColors.accentPurple),
                    underline: Container(
                      height: 2,
                      color: AppColors.accentPurple,
                    ),
                    onChanged: (double? newValue) {
                      if (newValue != null) {
                        viewModel.setPlaybackSpeed(newValue);
                      }
                    },
                    items: playbackSpeeds.map<DropdownMenuItem<double>>((double value) {
                      return DropdownMenuItem<double>(
                        value: value,
                        child: Text('${value}x', style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
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
