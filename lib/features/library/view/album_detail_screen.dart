import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';
import 'package:music_music/shared/widgets/mini_equalizer.dart';
import 'package:music_music/shared/widgets/mini_progress_bar.dart';
import 'package:music_music/shared/widgets/vinyl_album_cover.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumName;
  final String? artistName;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    this.artistName,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _doubleTapHintSeenKey = 'album_detail_double_tap_hint_seen';
  late final AnimationController _entryController;
  late final Animation<double> _entryCurve;
  bool _isPopping = false;
  bool _showDisk = true;
  bool _showDoubleTapHint = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _entryCurve = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();
    _loadDoubleTapHint();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _animateOutAndPop() async {
    if (_isPopping || !mounted) return;
    _isPopping = true;
    await _entryController.reverse();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _loadDoubleTapHint() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeen = prefs.getBool(_doubleTapHintSeenKey) ?? false;
    if (!mounted || alreadySeen) return;
    setState(() {
      _showDoubleTapHint = true;
    });
  }

  Future<void> _dismissDoubleTapHint() async {
    if (!_showDoubleTapHint) return;
    setState(() {
      _showDoubleTapHint = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doubleTapHintSeenKey, true);
  }

  String? _getAlbumArtwork(List<MusicEntity> musics) {
    for (final m in musics) {
      if (m.artworkUrl != null && m.artworkUrl!.isNotEmpty) {
        return m.artworkUrl;
      }
    }
    return null;
  }

  int? _getAlbumArtworkId(List<MusicEntity> musics) {
    for (final m in musics) {
      final id = m.sourceId ?? m.id;
      if (id != null) return id;
    }
    return null;
  }

  Future<void> _playPauseAlbum(
    PlaylistViewModel playlistVM,
    List<MusicEntity> musics,
  ) async {
    final current = playlistVM.currentMusic;
    final isSameAlbum = current != null && musics.any((m) => m.id == current.id);

    if (playlistVM.isPlaying && isSameAlbum) {
      await playlistVM.pause();
      return;
    }

    if (isSameAlbum) {
      await playlistVM.play();
      return;
    }

    await playlistVM.playMusic(musics, 0);
  }

  Future<void> _shuffleAlbum(
    PlaylistViewModel playlistVM,
    List<MusicEntity> musics,
  ) async {
    final enablingShuffle = !playlistVM.isShuffled;
    await playlistVM.toggleShuffle();

    if (!enablingShuffle) {
      return;
    }

    final current = playlistVM.currentMusic;
    final isSameAlbum = current != null && musics.any((m) => m.id == current.id);

    if (isSameAlbum && playlistVM.isPlaying) return;
    await playlistVM.playMusic(musics, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistVM = context.read<PlaylistViewModel>();
    final allMusics = context.select<HomeViewModel, List<MusicEntity>>((vm) => vm.musics);
    final dominantColor = context.select<PlaylistViewModel, Color>((vm) => vm.currentDominantColor);

    var musics = allMusics
        .where((m) => (m.album ?? 'Desconhecido') == widget.albumName)
        .toList();

    if (widget.artistName != null && widget.artistName!.isNotEmpty) {
      final filtered = musics
          .where((m) => m.artist.toLowerCase() == widget.artistName!.toLowerCase())
          .toList();
      if (filtered.isNotEmpty) musics = filtered;
    }

    final artwork = _getAlbumArtwork(musics);
    final artworkId = _getAlbumArtworkId(musics);
    ArtworkCache.preload(context, artwork);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _animateOutAndPop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    dominantColor.withValues(alpha: 0.94),
                    Colors.black,
                  ],
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
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
                          onPressed: _animateOutAndPop,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        Expanded(
                          child: Text(
                            widget.albumName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _showDisk ? 'Ocultar disco' : 'Mostrar disco',
                          onPressed: () {
                            setState(() {
                              _showDisk = !_showDisk;
                            });
                          },
                          icon: AnimatedRotation(
                            turns: _showDisk ? 0.0 : 0.5,
                            duration: const Duration(milliseconds: 220),
                            child: const Icon(Icons.keyboard_arrow_up_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 260),
                    firstCurve: Curves.easeOutCubic,
                    secondCurve: Curves.easeOutCubic,
                    crossFadeState: _showDisk
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: AnimatedBuilder(
                      animation: _entryCurve,
                      builder: (_, __) {
                        final t = _entryCurve.value;
                        final blur = lerpDouble(8, 0, t) ?? 0;
                        final scale = lerpDouble(0.94, 1.0, t) ?? 1.0;
                        return Opacity(
                          opacity: t,
                          child: Transform.scale(
                            scale: scale,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: blur,
                                sigmaY: blur,
                              ),
                              child: Hero(
                                tag: 'album_${widget.albumName}__${widget.artistName ?? ''}',
                                child: _RealisticDisk(
                                  dominantColor: dominantColor,
                                  child: VinylAlbumCover(
                                    artwork: artwork,
                                    audioId: artworkId,
                                    player: playlistVM.player,
                                    size: 214,
                                    showNeedle: false,
                                    motionProgress: t,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                  SizedBox(height: _showDisk ? 12 : 4),
                  Text(
                    '${musics.length} musicas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _entryCurve,
                  builder: (_, __) {
                    final t = _entryCurve.value;
                    final dy = lerpDouble(10, 0, t) ?? 0;
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, dy),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Selector<PlaylistViewModel, _PlayButtonState>(
                              selector: (_, vm) => _PlayButtonState(
                                currentId: vm.currentMusic?.id,
                                isPlaying: vm.isPlaying,
                              ),
                              builder: (_, state, __) {
                                final isCurrentAlbum = state.currentId != null &&
                                    musics.any((m) => m.id == state.currentId);
                                final shouldShowPause =
                                    isCurrentAlbum && state.isPlaying;
                                return _ActionButton(
                                  icon: shouldShowPause
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: dominantColor,
                                  big: true,
                                  onTap: () => _playPauseAlbum(playlistVM, musics),
                                );
                              },
                            ),
                            const SizedBox(width: 18),
                            Selector<PlaylistViewModel, bool>(
                              selector: (_, vm) => vm.isShuffled,
                              builder: (_, isShuffled, __) {
                                return _ActionButton(
                                  icon: Icons.shuffle,
                                  color: dominantColor,
                                  isActive: isShuffled,
                                  animateIcon: true,
                                  onTap: () => _shuffleAlbum(playlistVM, musics),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      );
                    },
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _showDoubleTapHint
                        ? Padding(
                            key: const ValueKey('double_tap_hint'),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _dismissDoubleTapHint,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Dica: toque 2x na música para abrir o player completo.',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        iconSize: 18,
                                        onPressed: _dismissDoubleTapHint,
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('no_double_tap_hint'),
                          ),
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
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCurrent
                                      ? dominantColor.withValues(alpha: 0.65)
                                      : Colors.white.withValues(alpha: 0.14),
                                  width: isCurrent ? 1.4 : 1.0,
                                ),
                                boxShadow: [
                                  ...shadows,
                                  BoxShadow(
                                    color: dominantColor.withValues(
                                      alpha: isCurrent ? 0.36 : 0.18,
                                    ),
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
                                    onDoubleTap: () {
                                      _dismissDoubleTapHint();
                                      Navigator.of(context).pushNamed(AppRoutes.player);
                                    },
                                    child: ListTile(
                                      leading: isCurrent
                                          ? MiniEqualizer(
                                              isPlaying: state.isPlaying,
                                              color: dominantColor,
                                            )
                                          : Text(
                                              '${index + 1}',
                                              style: theme.textTheme.labelLarge?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                      title: Text(
                                        music.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.15,
                                        ),
                                      ),
                                      subtitle: isCurrent
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  music.artist,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                StreamBuilder<Duration>(
                                                  stream: playlistVM.positionStream,
                                                  builder: (_, snapshot) {
                                                    return MiniProgressBar(
                                                      position: snapshot.data ?? Duration.zero,
                                                      duration: playlistVM.player.duration ?? Duration.zero,
                                                      color: dominantColor,
                                                    );
                                                  },
                                                ),
                                              ],
                                            )
                                          : Text(
                                              music.artist,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                                              ),
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
      ),
    );
  }
}

class _RealisticDisk extends StatelessWidget {
  final Widget child;
  final Color dominantColor;

  const _RealisticDisk({required this.child, required this.dominantColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 246,
      height: 246,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.22, -0.28),
          radius: 0.95,
          colors: [
            Colors.white.withValues(alpha: 0.26),
            dominantColor.withValues(alpha: 0.24),
            Colors.black.withValues(alpha: 0.56),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dominantColor.withValues(alpha: 0.54),
            blurRadius: 46,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.56),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.18, -0.18),
                colors: [
                  Colors.white.withValues(alpha: 0.14),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.36),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
          ),
          SizedBox(width: 214, height: 214, child: child),
          IgnorePointer(
            child: CustomPaint(
              size: const Size(214, 214),
              painter: _DiskDetailPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiskDetailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerR = size.width / 2;

    final groovePaint = Paint()..style = PaintingStyle.stroke;

    for (double r = outerR * 0.56; r < outerR * 0.99; r += 1.9) {
      groovePaint
        ..color = Colors.white.withValues(alpha: (r % 3.8 == 0) ? 0.068 : 0.04)
        ..strokeWidth = (r % 5.7 == 0) ? 1.15 : 0.82;
      canvas.drawCircle(center, r, groovePaint);
    }

    final shine = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.42),
        radius: 0.58,
        colors: [
          Colors.white.withValues(alpha: 0.31),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);

    canvas.drawCircle(center, outerR, shine);

    final glossArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.4
      ..shader = SweepGradient(
        startAngle: -1.25,
        endAngle: 0.3,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.24),
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 0.85, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerR - 8),
      -1.2,
      1.55,
      false,
      glossArc,
    );

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);

    canvas.drawCircle(center, outerR - 1.6, edge);

    final hub = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.06),
          Colors.black.withValues(alpha: 0.22),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: outerR * 0.12),
      );
    canvas.drawCircle(center, outerR * 0.11, hub);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NowPlayingState {
  final int? id;
  final bool isPlaying;

  const _NowPlayingState({required this.id, required this.isPlaying});

  @override
  bool operator ==(Object other) {
    return other is _NowPlayingState &&
        other.id == id &&
        other.isPlaying == isPlaying;
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

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool big;
  final bool isActive;
  final bool animateIcon;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.big = false,
    this.isActive = false,
    this.animateIcon = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
