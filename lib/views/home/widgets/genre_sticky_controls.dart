import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/music_entity.dart';
import '../../playlist/playlist_view_model.dart';

class GenreStickyControls extends SliverPersistentHeaderDelegate {
  final List<MusicEntity> musics;
  final Color color;

  GenreStickyControls({
    required this.musics,
    required this.color,
  });

  // 🔥 ALTURA CORRETA (obrigatório)
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
            color: theme.scaffoldBackgroundColor.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ▶️ PLAY / ⏸ PAUSE
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
                            color: color.withOpacity(0.25),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.7),
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

              // 🔀 SHUFFLE ANIMADO
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
                            ? color.withOpacity(0.45)
                            : color.withOpacity(0.2),
                        boxShadow: [
                          BoxShadow(
                            color: active
                                ? color.withOpacity(0.9)
                                : color.withOpacity(0.5),
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
