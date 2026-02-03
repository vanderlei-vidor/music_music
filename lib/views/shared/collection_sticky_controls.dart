import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/music_entity.dart';
import '../playlist/playlist_view_model.dart';

class CollectionStickyControls extends SliverPersistentHeaderDelegate {
  final List<MusicEntity> musics;
  final Color color;

  CollectionStickyControls({required this.musics, required this.color});

  // 🔒 ALTURA FIXA — REGRA DE OURO DO SLIVER
  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      height: maxExtent, // 🔒 trava o tamanho real
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withOpacity(0.88),
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ▶️ PLAY / ⏸ PAUSE
                Selector<PlaylistViewModel, bool>(
                  selector: (_, vm) => vm.isPlaying,
                  builder: (context, isPlaying, _) {
                    return _CircleButton(
                      color: color,
                      onTap: () {
                        final vm = context.read<PlaylistViewModel>();

                        final isSameCollection =
                            vm.currentMusic != null &&
                            musics.any((m) => m.id == vm.currentMusic!.id);

                        if (!isSameCollection) {
                          vm.playMusic(musics, 0);
                        } else {
                          vm.playPause();
                        }
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
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          key: ValueKey(isPlaying),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 28),

                // 🔀 SHUFFLE
                Selector<PlaylistViewModel, bool>(
                  selector: (_, vm) => vm.isShuffled,
                  builder: (context, active, _) {
                    return _CircleButton(
                      color: color,
                      active: active,
                      onTap: context.read<PlaylistViewModel>().toggleShuffle,
                      child: AnimatedRotation(
                        turns: active ? 0.125 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: const Icon(
                          Icons.shuffle,
                          color: Colors.white,
                          size: 24,
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
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

// ===============================
// 🔘 BOTÃO PREMIUM REUTILIZÁVEL
// ===============================
class _CircleButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback onTap;
  final bool active;

  const _CircleButton({
    required this.child,
    required this.color,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color.withOpacity(0.45) : color.withOpacity(0.25),
          boxShadow: [
            BoxShadow(
              color: active ? color.withOpacity(0.9) : color.withOpacity(0.6),
              blurRadius: active ? 24 : 18,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
