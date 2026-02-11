// lib/views/player/sliding_player_panel.dart

import 'package:flutter/material.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import 'mini_player_view.dart';
import 'player_view.dart';
import 'package:music_music/features/player/view_model/player_panel_controller.dart';

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
        // 🎵 MINI PLAYER (PREMIUM)
        // ======================
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
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
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: panel.progress < 0.05 ? 1 : 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.25),
                          Theme.of(context).cardColor.withOpacity(0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        // Glow controlado (não estoura)
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                        // Sombra profunda (flutuação)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 24),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1,
                      ),
                    ),
                    child: const MiniPlayerView(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
