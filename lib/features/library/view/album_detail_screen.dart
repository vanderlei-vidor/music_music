import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/vinyl_album_cover.dart';
import 'package:music_music/shared/widgets/mini_equalizer.dart';
import 'package:music_music/shared/widgets/mini_progress_bar.dart';
import 'package:music_music/core/theme/app_shadows.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;

  const AlbumDetailScreen({super.key, required this.albumName});

  String? _getAlbumArtwork(List<MusicEntity> musics) {
    for (final m in musics) {
      if (m.artworkUrl != null && m.artworkUrl!.isNotEmpty) {
        return m.artworkUrl;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistVM = context.watch<PlaylistViewModel>();

    final dominantColor = playlistVM.currentDominantColor;

    final musics = playlistVM.musics
        .where((m) => (m.album ?? 'Desconhecido') == albumName)
        .toList();

    final artwork = _getAlbumArtwork(musics);

    return Scaffold(
      body: Stack(
        children: [
          // 🎨 FUNDO CINEMATOGRÁFICO (ANIMADO)
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [dominantColor.withOpacity(0.95), Colors.black],
              ),
            ),
          ),

          // 🌫 BLUR
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.transparent),
          ),
          Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // 🎬 HEADER CINEMATOGRÁFICO
                  SliverAppBar(
                    expandedHeight: 340,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        albumName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (artwork != null)
                            Image.network(artwork, fit: BoxFit.cover),

                          Container(color: Colors.black.withOpacity(0.45)),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 48),

                              Hero(
                                tag: 'album_$albumName',
                                child: VinylAlbumCover(
                                  artwork: artwork,
                                  player: playlistVM.player,
                                  size: 190,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                '${musics.length} músicas',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🎵 LISTA DE MÚSICAS
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: musics.length,
                      (context, index) {
                        final music = musics[index];

                        final shadows =
                            Theme.of(context).extension<AppShadows>()?.surface ??
                                [];

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: shadows,
                          ),
                          child: ListTile(
                            leading: Consumer<PlaylistViewModel>(
                              builder: (_, vm, __) {
                                final isCurrent =
                                    vm.currentMusic?.id == music.id;

                                if (!isCurrent) {
                                  return Text('${index + 1}');
                                }

                                return MiniEqualizer(
                                  isPlaying: vm.isPlaying,
                                  color: dominantColor,
                                );
                              },
                            ),
                            title: Text(music.title),
                            subtitle: Consumer<PlaylistViewModel>(
                              builder: (_, vm, __) {
                                final isCurrent =
                                    vm.currentMusic?.id == music.id;

                                if (!isCurrent) {
                                  return Text(music.artist);
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(music.artist),
                                    StreamBuilder<Duration>(
                                      stream: vm.positionStream,
                                      builder: (_, snapshot) {
                                        return MiniProgressBar(
                                          position:
                                              snapshot.data ?? Duration.zero,
                                          duration:
                                              vm.player.duration ?? Duration.zero,
                                          color: dominantColor,
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                            onTap: () {
                              playlistVM.playMusic(musics, index);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              // 🎮 CONTROLES FIXOS (NÃO SCROLLAM)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: SafeArea(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: dominantColor.withOpacity(0.8),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: playlistVM.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: dominantColor,
                            big: true,
                            onTap: () {
                              final current = playlistVM.currentMusic;

                              final isSameAlbum =
                                  current != null &&
                                  musics.any((m) => m.id == current.id);

                              if (playlistVM.isPlaying) {
                                // ⏸ pausa normal
                                playlistVM.pause();
                              } else {
                                if (isSameAlbum) {
                                  // ▶️ retoma do ponto onde parou
                                  playlistVM.play();
                                } else {
                                  // ▶️ começa o álbum do zero
                                  playlistVM.playMusic(musics, 0);
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 28),
                          _ActionButton(
                            icon: Icons.shuffle,
                            color: dominantColor,
                            onTap: () async {
                              final current = playlistVM.currentMusic;

                              final isSameAlbum =
                                  current != null &&
                                  musics.any((m) => m.id == current.id);

                              await playlistVM.toggleShuffle();

                              // 🔥 se está tocando esse álbum, NÃO reinicia
                              if (isSameAlbum && playlistVM.isPlaying) {
                                // não faz nada — shuffle já foi aplicado
                                return;
                              }

                              // se não está tocando nada, começa o álbum
                              if (!playlistVM.isPlaying) {
                                playlistVM.playMusic(musics, 0);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===============================
// 🔘 BOTÃO PREMIUM
// ===============================
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool big;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = big ? 64.0 : 48.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.35),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.85), blurRadius: 28),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: big ? 34 : 26),
      ),
    );
  }
}



