import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:provider/provider.dart';

class PlaylistStickyControls extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 96;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final vm = context.watch<PlaylistViewModel>();
    final theme = Theme.of(context);

    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final scale = lerpDouble(1.0, 0.8, t)!;
    final padding = lerpDouble(20, 8, t)!;

    return SizedBox.expand(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Transform.scale(
              scale: scale,
              child: _PlayShuffleButton(vm: vm),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant PlaylistStickyControls oldDelegate) => true;
}

class _PlayShuffleButton extends StatelessWidget {
  final PlaylistViewModel vm;

  const _PlayShuffleButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                vm.isPlaying ? Icons.pause : Icons.play_arrow,
                key: ValueKey(vm.isPlaying),
                color: theme.colorScheme.onPrimary,
                size: 28,
              ),
            ),
            onPressed: vm.playPause,
          ),
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.onPrimary.withOpacity(0.3),
          ),
          IconButton(
            onPressed: vm.toggleShuffle,
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: vm.isShuffled
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.onPrimary.withOpacity(0.6),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                    child: RotationTransition(
                      turns: Tween(begin: 0.9, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  Icons.shuffle,
                  key: ValueKey(vm.isShuffled),
                  size: 24,
                  color: vm.isShuffled
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onPrimary.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

