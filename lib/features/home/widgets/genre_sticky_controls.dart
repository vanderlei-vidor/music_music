import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

class GenreStickyControls extends SliverPersistentHeaderDelegate {
  final List<MusicEntity> musics;
  final Color color;

  GenreStickyControls({
    required this.musics,
    required this.color,
  });

  // ðŸ”¥ ALTURA CORRETA (obrigatÃ³rio)
  @override
  double get minExtent => 112;

  @override
  double get maxExtent => 112;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // â–¶ï¸ PLAY / â¸ PAUSE
              Selector<PlaylistViewModel, bool>(
                selector: (_, vm) => vm.isPlaying,
                builder: (context, isPlaying, _) {
                  return GestureDetector(
                    onTap: context.read<PlaylistViewModel>().playPause,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                            child: child,
                          );
                        },
                        child: Container(
                          key: ValueKey(isPlaying),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.25),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.7),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 24),

              // ðŸ”€ SHUFFLE ANIMADO
              Selector<PlaylistViewModel, bool>(
                selector: (_, vm) => vm.isShuffled,
                builder: (context, active, _) {
                  return GestureDetector(
                    onTap: context.read<PlaylistViewModel>().toggleShuffle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? color.withValues(alpha: 0.45)
                            : color.withValues(alpha: 0.2),
                        boxShadow: [
                          BoxShadow(
                            color: active
                                ? color.withValues(alpha: 0.9)
                                : color.withValues(alpha: 0.5),
                            blurRadius: active ? 22 : 14,
                          ),
                        ],
                      ),
                      child: AnimatedRotation(
                        turns: active ? 0.125 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: const Icon(
                          Icons.shuffle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}


