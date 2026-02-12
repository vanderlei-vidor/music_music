import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

class AlbumFixedControls extends StatelessWidget {
  final List<MusicEntity> musics;
  final Color color;

  const AlbumFixedControls({
    super.key,
    required this.musics,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlaylistViewModel>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.7),
                blurRadius: 30,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ðŸ”€ SHUFFLE
              _CircleButton(
                icon: Icons.shuffle,
                active: vm.isShuffled,
                color: color,
                onTap: vm.toggleShuffle,
              ),

              const SizedBox(width: 24),

              // â–¶ï¸ PLAY / â¸ PAUSE
              _CircleButton(
                big: true,
                icon: vm.isPlaying ? Icons.pause : Icons.play_arrow,
                color: color,
                onTap: () {
                  if (vm.currentMusic == null ||
                      !musics.contains(vm.currentMusic)) {
                    vm.playMusic(musics, 0);
                  } else {
                    vm.playPause();
                  }
                },
              ),

              const SizedBox(width: 24),

              // â­ï¸ NEXT
              _CircleButton(
                icon: Icons.skip_next,
                color: color,
                onTap: vm.nextMusic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool big;
  final bool active;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.big = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = big ? 64.0 : 48.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? color.withValues(alpha: 0.45)
              : color.withValues(alpha: 0.25),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: active ? 0.9 : 0.6),
              blurRadius: active ? 28 : 20,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: big ? 34 : 26,
        ),
      ),
    );
  }
}



