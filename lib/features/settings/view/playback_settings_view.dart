import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/core/preferences/playback_preferences.dart';

/// Tela de configurações de Playback (Gapless e Crossfade)
class PlaybackSettingsView extends StatelessWidget {
  const PlaybackSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reprodução'),
        centerTitle: false,
      ),
      body: Consumer<PlaylistViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoadingConfig) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _SectionHeader(title: 'Transições'),
              
              // Gapless Playback
              SwitchListTile(
                title: const Text('Gapless Playback'),
                subtitle: const Text('Reproduzir faixas sem silêncio entre elas'),
                value: vm.gaplessEnabled,
                onChanged: vm.setGaplessEnabled,
                secondary: const Icon(Icons.auto_awesome_mosaic_rounded),
              ),

              const Divider(height: 24),

              // Crossfade
              SwitchListTile(
                title: const Text('Crossfade'),
                subtitle: const Text('Transição suave com sobreposição de faixas'),
                value: vm.crossfadeEnabled,
                onChanged: vm.setCrossfadeEnabled,
                secondary: const Icon(Icons.waves_rounded),
              ),

              // Slider de duração do Crossfade
              if (vm.crossfadeEnabled) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Duração',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '${vm.crossfadeSeconds}s',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: vm.crossfadeSeconds.toDouble(),
                        min: 0,
                        max: PlaybackPreferences.maxCrossfadeSeconds.toDouble(),
                        divisions: PlaybackPreferences.maxCrossfadeSeconds,
                        label: '${vm.crossfadeSeconds}s',
                        onChanged: (value) {
                          vm.setCrossfadeSeconds(value.round());
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Curto',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            'Longo',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 24),

              _SectionHeader(title: 'Informações'),
              
              // Info card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Como funciona',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Gapless: Remove silêncios entre faixas do mesmo álbum\n'
                        '• Crossfade: Sobreposição gradual ideal para playlists e DJ sets\n'
                        '• Use crossfade de 2-4s para transições suaves',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
