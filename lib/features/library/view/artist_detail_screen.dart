import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/app/routes.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/core/ui/genre_colors.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';
import 'package:music_music/shared/widgets/mini_equalizer.dart';
import 'package:music_music/shared/widgets/mini_progress_bar.dart';

class ArtistDetailView extends StatefulWidget {
  final String artistName;

  const ArtistDetailView({super.key, required this.artistName});

  @override
  State<ArtistDetailView> createState() => _ArtistDetailViewState();
}

class _ArtistDetailViewState extends State<ArtistDetailView> {
  bool _showArtistAvatar = true;

  String? _getArtistArtwork(List<MusicEntity> musics) {
    for (final m in musics) {
      if (m.artworkUrl != null && m.artworkUrl!.isNotEmpty) return m.artworkUrl;
    }
    return null;
  }

  int? _getArtistArtworkId(List<MusicEntity> musics) {
    for (final m in musics) {
      final id = m.sourceId ?? m.id;
      if (id != null) return id;
    }
    return null;
  }

  Future<void> _playPauseArtist(
    PlaylistViewModel playlistVM,
    List<MusicEntity> musics,
  ) async {
    final current = playlistVM.currentMusic;
    final isSameArtist = current != null && musics.any((m) => m.id == current.id);

    if (playlistVM.isPlaying && isSameArtist) {
      await playlistVM.pause();
      return;
    }

    if (isSameArtist) {
      await playlistVM.play();
      return;
    }

    await playlistVM.playMusic(musics, 0);
  }

  Future<void> _shuffleArtist(
    PlaylistViewModel playlistVM,
    List<MusicEntity> musics,
  ) async {
    final enablingShuffle = !playlistVM.isShuffled;
    await playlistVM.toggleShuffle();
    if (!enablingShuffle) return;

    final current = playlistVM.currentMusic;
    final isSameArtist = current != null && musics.any((m) => m.id == current.id);
    if (isSameArtist && playlistVM.isPlaying) return;
    await playlistVM.playMusic(musics, 0);
  }

  @override
  Widget build(BuildContext context) {
    final playlistVM = context.read<PlaylistViewModel>();
    final allMusics = context.select<HomeViewModel, List<MusicEntity>>((vm) => vm.musics);
    final musics = allMusics
        .where((m) => m.artist.toLowerCase() == widget.artistName.toLowerCase())
        .toList();

    final safeGenre = musics.isNotEmpty
        ? (musics.first.genre ?? widget.artistName)
        : widget.artistName;
    final color = GenreColorHelper.getColor(safeGenre);
    final artwork = _getArtistArtwork(musics);
    final artworkId = _getArtistArtworkId(musics);
    ArtworkCache.preload(context, artwork);

    final albumsCount = musics
        .map((m) => (m.album ?? '').trim())
        .where((a) => a.isNotEmpty)
        .toSet()
        .length;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.94), Colors.black],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(color: Colors.transparent),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      Expanded(
                        child: Text(
                          widget.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: _showArtistAvatar ? 'Ocultar artista' : 'Mostrar artista',
                        onPressed: () {
                          setState(() {
                            _showArtistAvatar = !_showArtistAvatar;
                          });
                        },
                        icon: AnimatedRotation(
                          turns: _showArtistAvatar ? 0.0 : 0.5,
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(Icons.keyboard_arrow_up_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 260),
                  firstCurve: Curves.easeOutCubic,
                  secondCurve: Curves.easeOutCubic,
                  crossFadeState: _showArtistAvatar
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Hero(
                    tag: 'artist_${widget.artistName}',
                    child: _ArtistHeroAvatar(
                      name: widget.artistName,
                      artworkUrl: artwork,
                      audioId: artworkId,
                      color: color,
                    ),
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
                SizedBox(height: _showArtistAvatar ? 12 : 4),
                Text(
                  '${musics.length} músicas • $albumsCount álbuns',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Selector<PlaylistViewModel, _PlayButtonState>(
                      selector: (_, vm) => _PlayButtonState(
                        currentId: vm.currentMusic?.id,
                        isPlaying: vm.isPlaying,
                      ),
                      builder: (_, state, __) {
                        final isCurrentArtist =
                            state.currentId != null && musics.any((m) => m.id == state.currentId);
                        final shouldShowPause = isCurrentArtist && state.isPlaying;

                        return _ArtistActionButton(
                          icon: shouldShowPause ? Icons.pause : Icons.play_arrow,
                          color: color,
                          big: true,
                          onTap: () => _playPauseArtist(playlistVM, musics),
                        );
                      },
                    ),
                    const SizedBox(width: 18),
                    Selector<PlaylistViewModel, bool>(
                      selector: (_, vm) => vm.isShuffled,
                      builder: (_, isShuffled, __) {
                        return _ArtistActionButton(
                          icon: Icons.shuffle,
                          color: color,
                          isActive: isShuffled,
                          animateIcon: true,
                          onTap: () => _shuffleArtist(playlistVM, musics),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 2, 0, 24),
                    itemCount: musics.length,
                    itemBuilder: (context, index) {
                      final music = musics[index];
                      ArtworkCache.preload(context, music.artworkUrl);
                      final shadows =
                          Theme.of(context).extension<AppShadows>()?.surface ?? [];

                      return Selector<PlaylistViewModel, _NowPlayingState>(
                        selector: (_, vm) => _NowPlayingState(
                          id: vm.currentMusic?.id,
                          isPlaying: vm.isPlaying,
                        ),
                        builder: (_, state, __) {
                          final isCurrent = state.id == music.id;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent
                                    ? color.withValues(alpha: 0.65)
                                    : Colors.white.withValues(alpha: 0.14),
                                width: isCurrent ? 1.4 : 1.0,
                              ),
                              boxShadow: [
                                ...shadows,
                                BoxShadow(
                                  color: color.withValues(alpha: isCurrent ? 0.32 : 0.16),
                                  blurRadius: isCurrent ? 24 : 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: InkWell(
                                  onTap: () => playlistVM.playMusic(musics, index),
                                  onDoubleTap: () => Navigator.of(context).pushNamed(AppRoutes.player),
                                  child: ListTile(
                                    leading: isCurrent
                                        ? MiniEqualizer(
                                            isPlaying: state.isPlaying,
                                            color: color,
                                          )
                                        : ArtworkThumb(
                                            artworkUrl: music.artworkUrl,
                                            audioId: music.sourceId ?? music.id,
                                          ),
                                    title: Text(
                                      music.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.15,
                                          ),
                                    ),
                                    subtitle: isCurrent
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                music.album ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              StreamBuilder<Duration>(
                                                stream: playlistVM.positionStream,
                                                builder: (_, snapshot) {
                                                  return MiniProgressBar(
                                                    position: snapshot.data ?? Duration.zero,
                                                    duration:
                                                        playlistVM.player.duration ?? Duration.zero,
                                                    color: color,
                                                  );
                                                },
                                              ),
                                            ],
                                          )
                                        : Text(
                                            music.album ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistHeroAvatar extends StatelessWidget {
  final String name;
  final String? artworkUrl;
  final int? audioId;
  final Color color;

  const _ArtistHeroAvatar({
    required this.name,
    required this.artworkUrl,
    required this.audioId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 126,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: [
            Colors.white.withValues(alpha: 0.2),
            color.withValues(alpha: 0.32),
            Colors.black.withValues(alpha: 0.42),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 26,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: artworkUrl != null || audioId != null
            ? ArtworkSquare(artworkUrl: artworkUrl, audioId: audioId, borderRadius: 999)
            : Container(
                color: color.withValues(alpha: 0.35),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
      ),
    );
  }
}

class _NowPlayingState {
  final int? id;
  final bool isPlaying;

  const _NowPlayingState({required this.id, required this.isPlaying});

  @override
  bool operator ==(Object other) {
    return other is _NowPlayingState && other.id == id && other.isPlaying == isPlaying;
  }

  @override
  int get hashCode => Object.hash(id, isPlaying);
}

class _PlayButtonState {
  final int? currentId;
  final bool isPlaying;

  const _PlayButtonState({required this.currentId, required this.isPlaying});

  @override
  bool operator ==(Object other) {
    return other is _PlayButtonState &&
        other.currentId == currentId &&
        other.isPlaying == isPlaying;
  }

  @override
  int get hashCode => Object.hash(currentId, isPlaying);
}

class _ArtistActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool big;
  final bool isActive;
  final bool animateIcon;

  const _ArtistActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.big = false,
    this.isActive = false,
    this.animateIcon = false,
  });

  @override
  State<_ArtistActionButton> createState() => _ArtistActionButtonState();
}

class _ArtistActionButtonState extends State<_ArtistActionButton> {
  bool _pressed = false;
  double _spinTurns = 0;

  void _handleTap() {
    if (widget.animateIcon) {
      setState(() {
        _spinTurns += 1;
      });
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.big ? 64.0 : 48.0;
    final iconSize = widget.big ? 34.0 : 26.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: widget.isActive ? 0.48 : 0.35),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: widget.isActive ? 0.95 : 0.85),
                blurRadius: widget.isActive ? 34 : 28,
              ),
            ],
          ),
          child: Center(
            child: AnimatedRotation(
              turns: widget.animateIcon ? _spinTurns : 0,
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              child: Icon(widget.icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}
