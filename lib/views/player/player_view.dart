import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;

import 'package:music_music/models/music_entity.dart';
import 'package:music_music/views/playlist/playlist_view_model.dart';

import 'package:music_music/widgets/animated_favorite_icon.dart';
import 'package:music_music/widgets/audio_wave.dart';
import 'package:music_music/widgets/play_pause_button.dart';
import 'package:music_music/widgets/progress_slider.dart';
import 'package:music_music/widgets/animated_shuffle_button.dart';
import 'package:music_music/widgets/RepeatButton.dart';
import 'package:music_music/widgets/speed_button.dart';
import 'package:music_music/widgets/vertical_volume_slider.dart';
import 'package:music_music/widgets/volume_equalizer.dart';

import '../favorites/favorites_view.dart';
import '../historico/MostPlayedView.dart';
import '../historico/recent_view.dart';
import '../playlist/playlists_screen.dart';

class PlayerView extends StatefulWidget {
  const PlayerView({super.key});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  bool _showVolumeSlider = false;
  Timer? _volumeTimer;

  void _toggleVolume() {
    setState(() => _showVolumeSlider = true);

    _volumeTimer?.cancel();
    _volumeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showVolumeSlider = false);
    });
  }

  @override
  void dispose() {
    _volumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<PlaylistViewModel>();
    final music = vm.currentMusic;

    if (music == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context, music),
      body: Stack(
        children: [
          /// 🌈 BACKGROUND PREMIUM
          Positioned.fill(child: _BackgroundArtwork(music: music)),

          /// 🎧 CONTEÚDO
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                /// 🎵 CAPA
                Hero(
                  tag: music.audioUrl,
                  child: _ArtworkCover(music: music),
                ),

                const SizedBox(height: 28),

                /// 📝 TÍTULO
                Text(
                  music.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                Text(
                  music.artist,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 32),

                /// 🌊 WAVE + SLIDER
                AudioWave(
                  isPlaying: vm.isPlaying,
                  color: theme.colorScheme.primary,
                ),

                const SizedBox(height: 10),

                StreamBuilder<Duration>(
                  stream: vm.positionStream,
                  builder: (_, posSnap) {
                    final position = posSnap.data ?? Duration.zero;

                    return StreamBuilder<Duration?>(
                      stream: vm.player.durationStream,
                      builder: (_, durSnap) {
                        return ProgressSlider(
                          position: position,
                          duration: durSnap.data ?? Duration.zero,
                          onSeek: vm.seek,
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 32),

                /// 🎮 CONTROLES
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShuffleButton(
                      isActive: vm.isShuffled,
                      onTap: vm.toggleShuffle,
                    ),
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.skip_previous),
                      onPressed: vm.previousMusic,
                    ),
                    PlayPauseButton(
                      isPlaying: vm.isPlaying,
                      size: 72,
                      color: theme.colorScheme.primary,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        vm.playPause();
                      },
                    ),
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.skip_next),
                      onPressed: vm.nextMusic,
                    ),
                    RepeatButton(
                      mode: vm.repeatMode,
                      onTap: vm.toggleRepeatMode,
                    ),
                    SpeedButton(
                      speed: vm.currentSpeed,
                      onTap: () => _openSpeed(context, vm),
                    ),
                  ],
                ),

                const Spacer(),
              ],
            ),
          ),

          /// 🎚 VOLUME
          VolumeEqualizer(volume: vm.player.volume),

          if (_showVolumeSlider)
            Positioned(
              right: 20,
              bottom: 120,
              child: VerticalVolumeSlider(
                volume: vm.player.volume,
                onChanged: vm.setVolume,
              ),
            ),
        ],
      ),
    );
  }

  // ===================== APP BAR =====================

  PreferredSizeWidget _buildAppBar(BuildContext context, MusicEntity music) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        AnimatedFavoriteIcon(
          isFavorite: music.isFavorite,
          activeColor: Colors.redAccent,
          onTap: () => context.read<PlaylistViewModel>().toggleFavorite(music),
        ),
        IconButton(
          icon: const Icon(Icons.playlist_play),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
          ),
        ),
        IconButton(icon: const Icon(Icons.volume_up), onPressed: _toggleVolume),
      ],
    );
  }

  // ===================== DRAWER =====================

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.music_note, size: 42, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  'Music Music 🎧',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          _drawerItem(
            context,
            Icons.history,
            'Tocadas recentemente',
            const RecentMusicsView(),
          ),

          _drawerItem(
            context,
            Icons.favorite,
            'Favoritas',
            const FavoritesView(),
          ),

          const Divider(),

          _drawerItem(
            context,
            Icons.playlist_play,
            'Playlists',
            const PlaylistsScreen(),
          ),

          _drawerItem(
            context,
            Icons.trending_up,
            'Mais tocadas',
            const MostPlayedView(),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }

  // ===================== SPEED =====================

  void _openSpeed(BuildContext context, PlaylistViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SpeedSheet(
        currentSpeed: vm.currentSpeed,
        onChanged: vm.setPlaybackSpeed,
      ),
    );
  }
}

/// =======================================================
/// 🎨 BACKGROUND COM BLUR DA CAPA
/// =======================================================

class _BackgroundArtwork extends StatelessWidget {
  final MusicEntity music;

  const _BackgroundArtwork({required this.music});

  @override
  Widget build(BuildContext context) {
    final image = music.artworkUrl;

    if (image == null) {
      return Container(color: Theme.of(context).scaffoldBackgroundColor);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(image, fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(color: Colors.black.withOpacity(0.4)),
        ),
      ],
    );
  }
}

/// =======================================================
/// 🎧 CAPA
/// =======================================================

class _ArtworkCover extends StatelessWidget {
  final MusicEntity music;

  const _ArtworkCover({required this.music});

  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(
      id: music.id!,
      type: ArtworkType.AUDIO,
      artworkFit: BoxFit.cover,
      artworkBorder: BorderRadius.circular(28),
      nullArtworkWidget: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.music_note,
          size: 80,
          color: Colors.white70,
        ),
      ),
    );
  }
}

