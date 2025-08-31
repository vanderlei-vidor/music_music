// lib/views/player/player_view.dart
import 'package:flutter/material.dart';
import 'package:music_music/views/playlist/playlists_screen.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../../core/theme/app_colors.dart';
import '../playlist/playlist_view_model.dart';
import '../../widgets/sleep_timer_button.dart'; // Mantive o import caso você queira reutilizar o widget em outro lugar.

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getRepeatButtonColor(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return Colors.white70;
      case LoopMode.one:
      case LoopMode.all:
        return AppColors.accentPurple;
    }
  }

  IconData _getRepeatButtonIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
      case LoopMode.all:
        return Icons.repeat;
      case LoopMode.one:
        return Icons.repeat_one;
    }
  }

  void _showCreatePlaylistDialog(BuildContext context, PlaylistViewModel viewModel) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Criar Nova Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome da Playlist',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentPurple),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                viewModel.createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Criar', style: TextStyle(color: AppColors.accentPurple)),
          ),
        ],
      ),
    );
  }

  // Novo método para exibir o diálogo do temporizador
  void _showSleepTimerDialog(BuildContext context, PlaylistViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Definir Temporizador', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('15 minutos', style: TextStyle(color: Colors.white)),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(minutes: 15));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('30 minutos', style: TextStyle(color: Colors.white)),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(minutes: 30));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('1 hora', style: TextStyle(color: Colors.white)),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(hours: 1));
                  Navigator.pop(context);
                },
              ),
              if (viewModel.hasSleepTimer)
                ListTile(
                  title: const Text('Cancelar Temporizador', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    viewModel.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlaylistsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _showCreatePlaylistDialog(context, Provider.of<PlaylistViewModel>(context, listen: false));
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      drawer: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          final List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
          return Drawer(
            backgroundColor: AppColors.cardBackground,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                  ),
                  child: Text(
                    'Configurações do Player',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.timer, color: AppColors.accentPurple),
                  title: const Text('Temporizador de Repouso', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showSleepTimerDialog(context, viewModel);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.speed, color: AppColors.accentPurple),
                  title: const Text('Velocidade de Reprodução', style: TextStyle(color: Colors.white)),
                  trailing: DropdownButton<double>(
                    value: viewModel.currentSpeed,
                    dropdownColor: AppColors.cardBackground,
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentPurple),
                    underline: Container(),
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
                  onTap: () {
                    // Sem ação, pois o DropdownButton já lida com a interação
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          final music = viewModel.currentMusic;
          if (music == null) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accentPurple));
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}