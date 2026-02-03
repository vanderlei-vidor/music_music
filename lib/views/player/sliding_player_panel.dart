// lib/views/player/sliding_player_panel.dart

import 'package:flutter/material.dart';
import 'package:music_music/views/home/home_view_model.dart';
import 'package:music_music/views/playlist/playlist_view_model.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import 'mini_player_view.dart';
import 'player_view.dart';
import 'player_panel_controller.dart';

class SlidingPlayerPanel extends StatelessWidget {
  final bool showGlow;

  const SlidingPlayerPanel({super.key, required this.showGlow});

  @override
  Widget build(BuildContext context) {
    final panel = context.watch<PlayerPanelController>();
    final playlistVM = context.read<PlaylistViewModel>();
    final color = playlistVM.currentDominantColor;

    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // ======================
        // 🎧 PLAYER FULL
        // ======================
        Positioned(
          top: screenHeight * (1 - panel.progress),
          left: 0,
          right: 0,
          height: screenHeight,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              final delta = details.primaryDelta! / screenHeight;
              context.read<PlayerPanelController>().update(
                panel.progress - delta,
              );
            },
            onVerticalDragEnd: (_) {
              if (panel.progress > 0.5) {
                context.read<PlayerPanelController>().open();
              } else {
                context.read<PlayerPanelController>().close();
              }
            },
            child: const PlayerView(),
          ),
        ),

        // ======================
        // 🎵 MINI PLAYER
        // ======================
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              final delta = details.primaryDelta! / screenHeight;
              context.read<PlayerPanelController>().update(
                panel.progress - delta,
              );
            },
            onVerticalDragEnd: (_) {
              if (panel.progress > 0.5) {
                context.read<PlayerPanelController>().open();
              } else {
                context.read<PlayerPanelController>().close();
              }
            },

            // 🔥 GLOW PREMIUM AQUI
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.95), Colors.black],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const MiniPlayerView(),
            ),
          ),
        ),
      ],
    );
  }
}
