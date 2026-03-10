// lib/views/player/mini_player_view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_music/core/theme/app_colors.dart';
import 'package:music_music/core/ui/neumorphic_wrapper.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/shared/widgets/mini_equalizer.dart';
import 'package:music_music/shared/widgets/animated_favorite_icon.dart';
import 'package:music_music/shared/widgets/animated_play_pause.dart';
import 'package:music_music/shared/widgets/mini_player_progress.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

class MiniPlayerView extends StatefulWidget {
  const MiniPlayerView({super.key});

  @override
  State<MiniPlayerView> createState() => _MiniPlayerViewState();
}

class _MiniPlayerViewState extends State<MiniPlayerView>
    with TickerProviderStateMixin {
  // Ã°Å¸Å½Âµ pulsaÃƒÂ§ÃƒÂ£o
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  // Ã°Å¸Å½Â¨ cor animada
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  Color _currentColor = Colors.black;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _colorAnimation = AlwaysStoppedAnimation(_currentColor);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = theme.extension<AppShadows>();
    final vm = context.read<PlaylistViewModel>();
    final music =
        context.select<PlaylistViewModel, MusicEntity?>((vm) => vm.currentMusic);
    final isPlaying =
        context.select<PlaylistViewModel, bool>((vm) => vm.isPlaying);
    final dominantColor =
        context.select<PlaylistViewModel, Color>((vm) => vm.currentDominantColor);

    _syncAnimationStates(dominantColor, isPlaying);

    final animatedColor = _colorAnimation.value ?? _currentColor;

    if (music == null) {
      return const SizedBox.shrink();
    }

    ArtworkCache.preload(context, music.artworkUrl);
    final artworkId = music.sourceId ?? music.id;

    return ScaleTransition(
      scale: _pulse,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;

              if (velocity < -200) {
                vm.nextMusic();
                HapticFeedback.lightImpact();
              } else if (velocity > 200) {
                vm.previousMusic();
                HapticFeedback.lightImpact();
              }
            },
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.player);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: music.artworkUrl != null
                            ? [
                                animatedColor.withValues(alpha: 0.95),
                                Colors.black.withValues(alpha: 0.9),
                              ]
                            : [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.85,
                                ),
                                theme.colorScheme.surface,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow:
                          shadows?.neumorphic ??
                          [
                            BoxShadow(
                              color: animatedColor.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 320;

                            return Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: artworkId == null
                                          ? _defaultArtwork(theme)
                                          : QueryArtworkWidget(
                                              id: artworkId,
                                              type: ArtworkType.AUDIO,
                                              artworkFit: BoxFit.cover,
                                              size: 200,
                                              nullArtworkWidget:
                                                  _defaultArtwork(theme),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        music.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        music.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (!isCompact)
                                  MiniEqualizer(
                                    isPlaying: isPlaying,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                if (!isCompact)
                                  NeumorphicWrapper(
                                    onTap: vm.previousMusic,
                                    child: Icon(
                                      Icons.skip_previous,
                                      size: 20,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: theme.brightness ==
                                            Brightness.light
                                        ? LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.primary
                                                  .withValues(alpha: 0.85),
                                            ],
                                          )
                                        : PremiumGradients.accentOrange,
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.brightness ==
                                                Brightness.light
                                            ? theme.colorScheme.primary
                                                .withValues(alpha: 0.35)
                                            : animatedColor.withValues(
                                                alpha: 0.6,
                                              ),
                                        blurRadius:
                                            theme.brightness == Brightness.light
                                                ? 18
                                                : 26,
                                        offset: theme.brightness ==
                                                Brightness.light
                                            ? const Offset(0, 8)
                                            : const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: PlayPauseButton(
                                    isPlaying: isPlaying,
                                    color: Colors.white,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      vm.playPause();
                                    },
                                  ),
                                ),
                                NeumorphicWrapper(
                                  onTap: vm.nextMusic,
                                  child: Icon(
                                    Icons.skip_next,
                                    size: 20,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (!isCompact)
                                  AnimatedFavoriteIcon(
                                    isFavorite: music.isFavorite,
                                    size: 26,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      vm.toggleFavorite(music);
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<Duration>(
                          stream: vm.positionStream,
                          builder: (_, posSnap) {
                            final position = posSnap.data ?? Duration.zero;
                            final duration = Duration(
                              milliseconds: music.duration ?? 0,
                            );
                            final total = duration.inMilliseconds;
                            final current = position.inMilliseconds.clamp(
                              0,
                              total,
                            );
                            final progress = total == 0 ? 0.0 : current / total;

                            return MiniPlayerProgress(
                              progress: progress,
                              color: theme.colorScheme.primary,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _syncAnimationStates(Color newColor, bool isPlaying) {
    if (newColor != _currentColor) {
      _colorAnimation = ColorTween(begin: _currentColor, end: newColor).animate(
        CurvedAnimation(parent: _colorController, curve: Curves.easeOutCubic),
      );

      _currentColor = newColor;
      _colorController.forward(from: 0);
    }

    if (isPlaying) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  Widget _defaultArtwork(ThemeData theme) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.music_note, color: theme.colorScheme.onPrimary),
    );
  }
}
