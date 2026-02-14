import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/vinyl_album_cover.dart';
import 'package:music_music/shared/widgets/mini_equalizer.dart';
import 'package:music_music/shared/widgets/mini_progress_bar.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;
  final String? artistName;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    this.artistName,
  });

  String? _getAlbumArtwork(List<MusicEntity> musics) {
    for (final m in musics) {
      if (m.artworkUrl != null && m.artworkUrl!.isNotEmpty) {
        return m.artworkUrl;
      }
    }
    return null;
  }

  int? _getAlbumArtworkId(List<MusicEntity> musics) {
    for (final m in musics) {
      final id = m.sourceId ?? m.id;
      if (id != null) return id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistVM = context.watch<PlaylistViewModel>();
    final allMusics = context.select<HomeViewModel, List<MusicEntity>>(
      (vm) => vm.musics,
    );

    final dominantColor = playlistVM.currentDominantColor;

    var musics = allMusics
        .where((m) => (m.album ?? 'Desconhecido') == albumName)
        .toList();
    if (artistName != null && artistName!.isNotEmpty) {
      final filtered = musics
          .where((m) => m.artist.toLowerCase() == artistName!.toLowerCase())
          .toList();
      if (filtered.isNotEmpty) {
        musics = filtered;
      }
    }

    final artwork = _getAlbumArtwork(musics);
    final artworkId = _getAlbumArtworkId(musics);
    ArtworkCache.preload(context, artwork);

    return Scaffold(
      body: Stack(
        children: [
          // ðŸŽ¨ FUNDO CINEMATOGRÃFICO (ANIMADO)
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [dominantColor.withValues(alpha: 0.95), Colors.black],
              ),
            ),
          ),

          // ðŸŒ« BLUR
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.transparent),
          ),
          Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ðŸŽ¬ HEADER CINEMATOGRÃFICO
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
                          ArtworkSquare(
                            artworkUrl: artwork,
                            audioId: artworkId,
                            borderRadius: 0,
                          ),

                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                          ),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 48),

                              Hero(
                                tag: 'album_${albumName}__${artistName ?? ''}',
                                child: VinylAlbumCover(
                                  artwork: artwork,
                                  audioId: artworkId,
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

                  // ðŸŽµ LISTA DE MÃšSICAS
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: musics.length,
                      (context, index) {
                        final music = musics[index];
                        ArtworkCache.preload(context, music.artworkUrl);

                        final shadows =
                            Theme.of(
                              context,
                            ).extension<AppShadows>()?.surface ??
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
                            leading:
                                Selector<PlaylistViewModel, _NowPlayingState>(
                                  selector: (_, vm) => _NowPlayingState(
                                    id: vm.currentMusic?.id,
                                    isPlaying: vm.isPlaying,
                                  ),
                                  builder: (_, state, __) {
                                    final isCurrent = state.id == music.id;
                                    if (!isCurrent) {
                                      return Text('${index + 1}');
                                    }
                                    return MiniEqualizer(
                                      isPlaying: state.isPlaying,
                                      color: dominantColor,
                                    );
                                  },
                                ),
                            title: Text(music.title),
                            subtitle:
                                Selector<PlaylistViewModel, _NowPlayingState>(
                                  selector: (_, vm) => _NowPlayingState(
                                    id: vm.currentMusic?.id,
                                    isPlaying: vm.isPlaying,
                                  ),
                                  builder: (_, state, __) {
                                    final isCurrent = state.id == music.id;
                                    if (!isCurrent) {
                                      return Text(music.artist);
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(music.artist),
                                        StreamBuilder<Duration>(
                                          stream: playlistVM.positionStream,
                                          builder: (_, snapshot) {
                                            return MiniProgressBar(
                                              position:
                                                  snapshot.data ??
                                                  Duration.zero,
                                              duration:
                                                  playlistVM.player.duration ??
                                                  Duration.zero,
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
              // ðŸŽ® CONTROLES FIXOS (NÃƒO SCROLLAM)
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
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: dominantColor.withValues(alpha: 0.8),
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
                                // â¸ pausa normal
                                playlistVM.pause();
                              } else {
                                if (isSameAlbum) {
                                  // â–¶ï¸ retoma do ponto onde parou
                                  playlistVM.play();
                                } else {
                                  // â–¶ï¸ comeÃ§a o Ã¡lbum do zero
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

                              // ðŸ”¥ se estÃ¡ tocando esse Ã¡lbum, NÃƒO reinicia
                              if (isSameAlbum && playlistVM.isPlaying) {
                                // nÃ£o faz nada â€” shuffle jÃ¡ foi aplicado
                                return;
                              }

                              // se nÃ£o estÃ¡ tocando nada, comeÃ§a o Ã¡lbum
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

class _NowPlayingState {
  final int? id;
  final bool isPlaying;

  const _NowPlayingState({required this.id, required this.isPlaying});

  @override
  bool operator ==(Object other) {
    return other is _NowPlayingState &&
        other.id == id &&
        other.isPlaying == isPlaying;
  }

  @override
  int get hashCode => Object.hash(id, isPlaying);
}

// ===============================
// ðŸ”˜ BOTÃƒO PREMIUM
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
          color: color.withValues(alpha: 0.35),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.85), blurRadius: 28),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: big ? 34 : 26),
      ),
    );
  }
}
