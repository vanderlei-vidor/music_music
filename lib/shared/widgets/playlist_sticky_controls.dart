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
    final isPlaying =
        context.select<PlaylistViewModel, bool>((vm) => vm.isPlaying);
    final isShuffled =
        context.select<PlaylistViewModel, bool>((vm) => vm.isShuffled);
    final vm = context.read<PlaylistViewModel>();
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
              child: _PlayShuffleButton(
                isPlaying: isPlaying,
                isShuffled: isShuffled,
                onPlayPause: vm.playPause,
                onToggleShuffle: vm.toggleShuffle,
              ),
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
  final bool isPlaying;
  final bool isShuffled;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleShuffle;

  const _PlayShuffleButton({
    required this.isPlaying,
    required this.isShuffled,
    required this.onPlayPause,
    required this.onToggleShuffle,
  });

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
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
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
                isPlaying ? Icons.pause : Icons.play_arrow,
                key: ValueKey(isPlaying),
                color: theme.colorScheme.onPrimary,
                size: 28,
              ),
            ),
            onPressed: onPlayPause,
          ),
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
          ),
          IconButton(
            onPressed: onToggleShuffle,
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isShuffled
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
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
                  key: ValueKey(isShuffled),
                  size: 24,
                  color: isShuffled
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


