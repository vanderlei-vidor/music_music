import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/core/ui/genre_colors.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/shared/widgets/collection_sticky_controls.dart';
import 'package:music_music/shared/widgets/mini_equalizer.dart';
import 'package:music_music/shared/widgets/mini_progress_bar.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';

class ArtistDetailView extends StatelessWidget {
  final String artistName;

  const ArtistDetailView({
    super.key,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context) {
    final playlistVM = context.read<PlaylistViewModel>();
    final allMusics =
        context.select<PlaylistViewModel, List<MusicEntity>>((vm) => vm.musics);

    // ðŸŽ¶ mÃºsicas do artista
    final musics = allMusics
        .where(
          (m) => m.artist.toLowerCase() == artistName.toLowerCase(),
        )
        .toList();

    final safeGenre =
        musics.isNotEmpty ? musics.first.genre ?? artistName : artistName;

    final color = GenreColorHelper.getColor(safeGenre);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ðŸŽ¬ HEADER CINEMATOGRÃFICO
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,

            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Hero(
                tag: 'artist_$artistName',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ðŸŽ¨ FUNDO
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.95),
                            Colors.black,
                          ],
                        ),
                      ),
                    ),

                    // ðŸŒ« BLUR
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                    ),

                    // ðŸŽ¤ CONTEÃšDO CENTRAL
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: color.withValues(alpha: 0.3),
                            child: Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 12),

                         // Text(
                        //    artistName,
                        //    style: Theme.of(context)
                       //         .textTheme
                       //         .headlineSmall
                       //         ?.copyWith(
                      //            color: Colors.white,
                      //            fontWeight: FontWeight.bold,
                     //           ),
                    //      ),

                          const SizedBox(height: 6),

                          Text(
                            '${musics.length} mÃºsicas',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ðŸ”¥ STICKY CONTROLS
          SliverPersistentHeader(
            pinned: true,
            delegate: CollectionStickyControls(
              musics: musics,
              color: color,
            ),
          ),

          // ðŸŽµ LISTA DE MÃšSICAS
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: musics.length,
              (context, index) {
                final music = musics[index];
                ArtworkCache.preload(context, music.artworkUrl);

                final shadows =
                    Theme.of(context).extension<AppShadows>()?.surface ?? [];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: shadows,
                  ),
                  child: ListTile(
                    leading: Selector<PlaylistViewModel, _NowPlayingState>(
                      selector: (_, vm) => _NowPlayingState(
                        id: vm.currentMusic?.id,
                        isPlaying: vm.isPlaying,
                      ),
                      builder: (_, state, __) {
                        final isCurrent = state.id == music.id;
                        if (!isCurrent) {
                          return const Icon(Icons.music_note);
                        }
                        return MiniEqualizer(
                          isPlaying: state.isPlaying,
                          color: color,
                          size: 22,
                        );
                      },
                    ),
                    title: Text(music.title),
                    subtitle: Selector<PlaylistViewModel, _NowPlayingState>(
                      selector: (_, vm) => _NowPlayingState(
                        id: vm.currentMusic?.id,
                        isPlaying: vm.isPlaying,
                      ),
                      builder: (_, state, __) {
                        final isCurrent = state.id == music.id;
                        if (!isCurrent) {
                          return Text(music.album ?? '');
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(music.album ?? ''),
                            StreamBuilder<Duration>(
                              stream: playlistVM.positionStream,
                              builder: (context, snapshot) {
                                final position =
                                    snapshot.data ?? Duration.zero;
                                final duration =
                                    playlistVM.player.duration ?? Duration.zero;

                                return MiniProgressBar(
                                  position: position,
                                  duration: duration,
                                  color: color,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    onTap: () async {
                      await playlistVM.playMusic(musics, index);

                      if (context.mounted) {
                        Navigator.pushNamed(context, AppRoutes.player);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
    return other is _NowPlayingState &&
        other.id == id &&
        other.isPlaying == isPlaying;
  }

  @override
  int get hashCode => Object.hash(id, isPlaying);
}




