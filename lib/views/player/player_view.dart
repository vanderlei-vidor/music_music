// lib/views/player/player_view.dart

import 'dart:io';
import 'dart:async'; // 👈 Importante: Adicione esta linha para usar o Timer

import 'package:flutter/material.dart';
import 'package:music_music/views/playlist/playlists_screen.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../../core/theme/app_colors.dart';
import '../playlist/playlist_view_model.dart';
import '../../widgets/sleep_timer_button.dart'; // Mantido para referência, mas não usado aqui

class PlayerView extends StatefulWidget {
  const PlayerView({super.key});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  // ✅ Estado e temporizador para o slider de volume
  bool _showVolumeSlider = false;
  Timer? _volumeSliderTimer;

  // ✅ Método para mostrar e esconder o slider
  void _toggleVolumeSlider(bool show) {
    setState(() {
      _showVolumeSlider = show;
    });

    _volumeSliderTimer?.cancel();

    if (show) {
      _volumeSliderTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) { // Garante que o widget ainda está na árvore
          setState(() {
            _showVolumeSlider = false;
          });
        }
      });
    }
  }

  // ✅ Lembre de cancelar o timer quando o widget for descartado
  @override
  void dispose() {
    _volumeSliderTimer?.cancel();
    super.dispose();
  }

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

  // ✅ Método para mostrar o diálogo de velocidade de reprodução
  void _showPlaybackSpeedDialog(BuildContext context, PlaylistViewModel viewModel) {
    final List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Velocidade de Reprodução', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: playbackSpeeds.map((speed) {
              return RadioListTile<double>(
                title: Text('${speed}x', style: const TextStyle(color: Colors.white)),
                value: speed,
                groupValue: viewModel.currentSpeed,
                activeColor: AppColors.accentPurple,
                onChanged: (double? newValue) {
                  if (newValue != null) {
                    viewModel.setPlaybackSpeed(newValue);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PlaylistViewModel>();
    final music = viewModel.currentMusic;

    if (music == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPurple));
    }

    final double imageSize = MediaQuery.of(context).size.width * 0.9 > 400
        ? 400
        : MediaQuery.of(context).size.width * 0.9;

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
                  onTap: () {
                    Navigator.of(context).pop();
                    _showPlaybackSpeedDialog(context, viewModel);
                  },
                  trailing: Text(
                    '${viewModel.currentSpeed}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                // ✅ Novo item de menu para o volume
                ListTile(
                  leading: const Icon(Icons.volume_up, color: AppColors.accentPurple),
                  title: const Text('Volume', style: TextStyle(color: Colors.white)),
                  trailing: Text(
                    (viewModel.player.volume * 100).toInt().toString(), // Exibe o volume em porcentagem
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _toggleVolumeSlider(true);
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, Color(0xFF13101E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: Platform.isWindows || Platform.isLinux || Platform.isMacOS
                        ? _buildDefaultArtwork()
                        : QueryArtworkWidget(
                            id: music.albumId ?? 0,
                            type: ArtworkType.ALBUM,
                            artworkBorder: BorderRadius.circular(20),
                            nullArtworkWidget: _buildDefaultArtwork(),
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
                    music.artist ?? "Artista Desconhecido",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 30),
                  StreamBuilder<Duration?>(
                    stream: viewModel.player.durationStream,
                    builder: (context, durationSnapshot) {
                      final totalDuration = durationSnapshot.data ?? Duration.zero;

                      return StreamBuilder<Duration>(
                        stream: viewModel.positionStream,
                        builder: (context, positionSnapshot) {
                          final position = positionSnapshot.data ?? Duration.zero;

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
          ),
          // ✅ O Slider de volume flutuante
          Positioned(
            bottom: 120, // Ajuste a posição conforme sua UI
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _showVolumeSlider ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildVolumeSlider(viewModel),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Novo widget que constrói o slider de volume
  Widget _buildVolumeSlider(PlaylistViewModel viewModel) {
  return StreamBuilder<double>(
    stream: viewModel.player.volumeStream,
    builder: (context, snapshot) {
      final currentVolume = snapshot.data ?? viewModel.player.volume;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // ✅ O Ícone agora é um IconButton
            IconButton(
              icon: Icon(
                currentVolume == 0 ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
              onPressed: () {
                if (currentVolume > 0) {
                  viewModel.setVolume(0.0); // Muta o volume
                } else {
                  // Aqui, você pode restaurar para um volume padrão, por exemplo, 0.5
                  viewModel.setVolume(0.5); // Desmuta para um valor padrão
                }
                _toggleVolumeSlider(true); // Garante que o slider não desapareça
              },
            ),
            Expanded(
              child: Slider(
                min: 0.0,
                max: 1.0,
                value: currentVolume,
                activeColor: AppColors.accentPurple,
                inactiveColor: Colors.white.withOpacity(0.3),
                onChanged: (newVolume) {
                  viewModel.setVolume(newVolume);
                  _toggleVolumeSlider(true); // Reinicia o temporizador a cada ajuste
                },
              ),
            ),
          ],
        ),
      );
    },
  );
  }


  Widget _buildDefaultArtwork() {
    return Container(
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
    );
  }
}