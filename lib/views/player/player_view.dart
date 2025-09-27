// lib/views/player/player_view.dart

import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:audio_visualizer/utils.dart';
import 'package:audio_visualizer/visualizers/audio_spectrum.dart';
import 'package:audio_visualizer/visualizers/bar_visualizer.dart';
import 'package:audio_visualizer/visualizers/rainbow_visualizer.dart';
import 'package:flutter/material.dart';
import 'package:music_music/core/theme/theme_manager.dart';
import 'package:music_music/views/playlist/playlists_screen.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../playlist/playlist_view_model.dart';
import '../../widgets/sleep_timer_button.dart';
import 'package:permission_handler/permission_handler.dart';

class PlayerView extends StatefulWidget {
  const PlayerView({super.key});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> with TickerProviderStateMixin {
  bool _showVolumeSlider = false;
  Timer? _volumeSliderTimer;

  ScrollController? _titleScrollController;
  AnimationController? _scrollAnimationController;
  Animation<double>? _scrollAnimation;
  

  @override
  void initState() {
    super.initState();

   
    _titleScrollController = ScrollController();
    _scrollAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // 👇 Remova a inicialização da animação aqui (vai ser feita no LayoutBuilder)
  }

  

  @override
  void dispose() {
    _titleScrollController?.dispose();
    _scrollAnimationController?.dispose();
    _volumeSliderTimer?.cancel();
    super.dispose();
  }

  void _toggleVolumeSlider(bool show) {
    setState(() {
      _showVolumeSlider = show;
    });

    _volumeSliderTimer?.cancel();

    if (show) {
      _volumeSliderTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showVolumeSlider = false;
          });
        }
      });
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ✅ Atualizado: usa o tema
  Color _getRepeatButtonColor(BuildContext context, LoopMode mode) {
    final theme = Theme.of(context);
    switch (mode) {
      case LoopMode.off:
        return theme.colorScheme.onSurface.withOpacity(0.7);
      case LoopMode.one:
      case LoopMode.all:
        return theme.colorScheme.primary;
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

  void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  void _showSleepTimerDialog(
    BuildContext context,
    PlaylistViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            'Definir Temporizador',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  '15 minutos',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(minutes: 15));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(
                  '30 minutos',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(minutes: 30));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(
                  '1 hora',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                onTap: () {
                  viewModel.setSleepTimer(const Duration(hours: 1));
                  Navigator.pop(context);
                },
              ),
              if (viewModel.hasSleepTimer)
                ListTile(
                  title: Text(
                    'Cancelar Temporizador',
                    style: TextStyle(color: Colors.red),
                  ),
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

  void _showPlaybackSpeedDialog(
    BuildContext context,
    PlaylistViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            'Velocidade de Reprodução',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: playbackSpeeds.map((speed) {
              return RadioListTile<double>(
                title: Text(
                  '${speed}x',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                value: speed,
                groupValue: viewModel.currentSpeed,
                activeColor: theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    final viewModel = context.watch<PlaylistViewModel>();
    final music = viewModel.currentMusic;

    if (music == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
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
            icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
            tooltip: 'Menu',
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.playlist_play, color: theme.colorScheme.onSurface),
            tooltip: 'Ver todas playlists',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaylistsScreen(),
                ),
              );
            },
          ),
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
        ],
      ),
      extendBodyBehindAppBar: true,
      drawer: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          final theme = Theme.of(context);
          final themeManager = Provider.of<ThemeManager>(context);
          return Drawer(
            backgroundColor: theme.cardColor,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: theme.colorScheme.primary),
                  child: Text(
                    'Configurações do Player',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    themeManager.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    themeManager.themeMode == ThemeMode.dark
                        ? 'Modo Escuro'
                        : 'Modo Claro',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  onTap: () {
                    themeManager.toggleTheme();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.timer, color: theme.colorScheme.primary),
                  title: Text(
                    'Temporizador de Repouso',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showSleepTimerDialog(context, viewModel);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.speed, color: theme.colorScheme.primary),
                  title: Text(
                    'Velocidade de Reprodução',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showPlaybackSpeedDialog(context, viewModel);
                  },
                  trailing: Text(
                    '${viewModel.currentSpeed}x',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.volume_up,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Volume',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  trailing: Text(
                    (viewModel.player.volume * 100).toInt().toString(),
                    style: TextStyle(color: theme.colorScheme.onSurface),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.scaffoldBackgroundColor,
                  // Para manter o efeito escuro no fundo, usamos uma cor mais escura baseada no tema
                  theme.brightness == Brightness.dark
                      ? const Color(0xFF13101E)
                      : theme.scaffoldBackgroundColor.withOpacity(0.9),
                ],
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
                    child:
                        Platform.isWindows ||
                            Platform.isLinux ||
                            Platform.isMacOS
                        ? _buildDefaultArtwork(context)
                        : QueryArtworkWidget(
                            id: music.albumId ?? 0,
                            type: ArtworkType.ALBUM,
                            artworkBorder: BorderRadius.circular(20),
                            nullArtworkWidget: _buildDefaultArtwork(context),
                          ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 30,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final containerWidth = constraints.maxWidth;

                        // Mede a largura do texto
                        final textPainter = TextPainter(
                          text: TextSpan(
                            text: music.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                        )..layout();

                        final textWidth = textPainter.size.width;
                        const double extraMargin = 40.0;
                        // Cancela animação anterior
                        _scrollAnimation?.removeListener(() {});
                        _scrollAnimationController?.stop();

                        // Velocidade constante
                        const double pixelsPerSecond = 30.0;
                        // Distância total a percorrer: da direita (fora da tela) até sair pela esquerda
                        final totalDistance =
                            containerWidth + textWidth + extraMargin;
                        final durationMs =
                            (totalDistance / pixelsPerSecond * 1000)
                                .toInt()
                                .clamp(4000, 25000);

                        _scrollAnimationController?.duration = Duration(
                          milliseconds: durationMs,
                        );

                        // Animação: começa em containerWidth (texto à direita), termina em -textWidth (texto à esquerda)
                        _scrollAnimation =
                            Tween<double>(
                                begin: containerWidth,
                                end: -textWidth - extraMargin,
                              ).animate(
                                CurvedAnimation(
                                  parent: _scrollAnimationController!,
                                  curve: Curves.linear,
                                ),
                              )
                              ..addListener(() {
                                // Já está seguro
                              })
                              ..addStatusListener((status) {
                                if (status == AnimationStatus.completed &&
                                    mounted) {
                                  // Reinicia com um pequeno delay para "respirar"
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () {
                                      if (mounted &&
                                          _scrollAnimationController != null) {
                                        _scrollAnimationController!.reset();
                                        _scrollAnimationController!.forward();
                                      }
                                    },
                                  );
                                }
                              });

                        _scrollAnimationController!.forward();

                        return AnimatedBuilder(
                          animation: _scrollAnimation!,
                          builder: (context, child) {
                            return OverflowBox(
                              minWidth: containerWidth,
                              maxWidth: containerWidth,
                              child: Transform.translate(
                                offset: Offset(_scrollAnimation!.value, 0),
                                child: Text(
                                  music.title,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 5),
                  Center(
                    child: Text(
                      music.artist ?? "Artista Desconhecido",
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Equalizador simulado (sempre visível, sem permissão)
                  

                  StreamBuilder<Duration?>(
                    stream: viewModel.player.durationStream,
                    builder: (context, durationSnapshot) {
                      final totalDuration =
                          durationSnapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration>(
                        stream: viewModel.positionStream,
                        builder: (context, positionSnapshot) {
                          final position =
                              positionSnapshot.data ?? Duration.zero;
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4.0,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8.0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16.0,
                                  ),
                                  activeTrackColor: theme.colorScheme.primary,
                                  inactiveTrackColor: theme
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3),
                                  thumbColor: theme.colorScheme.primary,
                                  overlayColor: theme.colorScheme.primary
                                      .withOpacity(0.2),
                                ),
                                child: Slider(
                                  value: totalDuration.inMilliseconds > 0
                                      ? position.inMilliseconds.toDouble()
                                      : 0.0,
                                  min: 0.0,
                                  max: totalDuration.inMilliseconds.toDouble(),
                                  onChanged: (double value) {},
                                  onChangeEnd: (double value) {
                                    viewModel.seek(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(totalDuration),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
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
                        icon: Icon(
                          Icons.shuffle,
                          size: 28,
                          color: viewModel.isShuffled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        onPressed: viewModel.toggleShuffle,
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous,
                          size: 40,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: viewModel.previousMusic,
                      ),
                      const SizedBox(width: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            viewModel.playerState == PlayerState.playing
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 40,
                            color: theme.colorScheme.onPrimary,
                          ),
                          onPressed: viewModel.playPause,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Icon(
                          Icons.skip_next,
                          size: 40,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: viewModel.nextMusic,
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Icon(
                          _getRepeatButtonIcon(viewModel.repeatMode),
                          size: 28,
                          color: _getRepeatButtonColor(
                            context,
                            viewModel.repeatMode,
                          ),
                        ),
                        onPressed: viewModel.toggleRepeatMode,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _showVolumeSlider ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildVolumeSlider(context, viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeSlider(BuildContext context, PlaylistViewModel viewModel) {
    final theme = Theme.of(context);
    return StreamBuilder<double>(
      stream: viewModel.player.volumeStream,
      builder: (context, snapshot) {
        final currentVolume = snapshot.data ?? viewModel.player.volume;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  currentVolume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  if (currentVolume > 0) {
                    viewModel.setVolume(0.0);
                  } else {
                    viewModel.setVolume(0.5);
                  }
                  _toggleVolumeSlider(true);
                },
              ),
              Expanded(
                child: Slider(
                  min: 0.0,
                  max: 1.0,
                  value: currentVolume,
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: theme.colorScheme.onSurface.withOpacity(0.3),
                  onChanged: (newVolume) {
                    viewModel.setVolume(newVolume);
                    _toggleVolumeSlider(true);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultArtwork(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.music_note,
        size: 100,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

