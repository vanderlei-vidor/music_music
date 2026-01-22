// lib/views/player/mini_player_view.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_music/widgets/mini_equalizer.dart';
import 'package:provider/provider.dart';

import 'package:music_music/widgets/animated_favorite_icon.dart';
import 'package:music_music/widgets/animated_play_pause.dart';
import 'package:music_music/views/player/player_view.dart';
import 'package:music_music/views/playlist/playlist_view_model.dart';
import 'package:music_music/widgets/mini_player_progress.dart';

class MiniPlayerView extends StatelessWidget {
  const MiniPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<PlaylistViewModel>(
      builder: (context, vm, _) {
        final music = vm.currentMusic;
        final duration = vm.player.duration;

        if (music == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,

                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;

                  // ⬅️ próxima música
                  if (velocity < -200) {
                    vm.nextMusic();
                    HapticFeedback.lightImpact();
                  }
                  // ➡️ música anterior
                  else if (velocity > 200) {
                    vm.previousMusic();
                    HapticFeedback.lightImpact();
                  }
                },

                child: InkWell(
                  borderRadius: BorderRadius.circular(20),

                  // 👉 TAP abre o player
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerView()),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.88),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 🎨 ARTWORK
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: music.artworkUrl != null
                                  ? Image.network(
                                      music.artworkUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _defaultArtwork(theme),
                                    )
                                  : _defaultArtwork(theme),
                            ),

                            const SizedBox(width: 12),

                            // 🎵 TÍTULO / ARTISTA
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          music.title,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          music.artist,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  MiniEqualizer(
                                    isPlaying: vm.isPlaying,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              onPressed: vm.previousMusic,
                            ),

                            PlayPauseButton(
                              isPlaying: vm.isPlaying,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                vm.playPause();
                              },
                            ),

                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              onPressed: vm.nextMusic,
                            ),

                            AnimatedFavoriteIcon(
                              isFavorite: music.isFavorite,
                              size: 26,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                vm.toggleFavorite(music);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
        );
      },
    );
  }

  Widget _defaultArtwork(ThemeData theme) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.music_note, color: theme.colorScheme.onPrimary),
    );
  }
}
