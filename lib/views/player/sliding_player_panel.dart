// lib/views/player/sliding_player_panel.dart

import 'package:flutter/material.dart';
import 'package:music_music/views/home/home_view_model.dart';
import 'package:provider/provider.dart';

import 'mini_player_view.dart';
import 'player_view.dart';
import 'player_panel_controller.dart';

class SlidingPlayerPanel extends StatelessWidget {
  final bool showGlow;

  const SlidingPlayerPanel({super.key, required this.showGlow});

  @override
  Widget build(BuildContext context) {
    final panel = context.watch<PlayerPanelController>();
    final homeVM = context.watch<HomeViewModel>();

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
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: homeVM.showMiniPlayerGlow
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.55),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ]
                    : [],
              ),
              child: const MiniPlayerView(),
            ),
          ),
        ),
      ],
    );
  }
}
