import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

class FolderStickyControls extends SliverPersistentHeaderDelegate {
  final List<MusicEntity> musics;
  final Color color;

  FolderStickyControls({required this.musics, required this.color});

  @override
  double get minExtent => 82;

  @override
  double get maxExtent => 82;

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
        child: SizedBox(
          height: maxExtent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withOpacity(0.85),
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ▶️ PLAY / ⏸ PAUSE
                Consumer<PlaylistViewModel>(
                  builder: (context, vm, _) {
                    return GestureDetector(
                      onTap: () {
                        vm.playPause();
                      },
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
                          key: ValueKey(vm.isPlaying),
                          width: 48,
                          height: 48,
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
                            vm.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 24),

                // 🔀 SHUFFLE ANIMADO
                Consumer<PlaylistViewModel>(
                  builder: (context, vm, _) {
                    final active = vm.isShuffled;

                    return GestureDetector(
                      onTap: () {
                        vm.toggleShuffle();
                      },
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
                          child: const Icon(Icons.shuffle, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
bool shouldRebuild(covariant FolderStickyControls oldDelegate) {
  return oldDelegate.color != color ||
         oldDelegate.musics.length != musics.length;
}
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.25),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.6), blurRadius: 18),
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

