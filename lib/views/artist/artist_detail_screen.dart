import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/music_entity.dart';
import '../../core/ui/genre_colors.dart';
import '../playlist/playlist_view_model.dart';
import '../player/player_view.dart';
import '../shared/collection_sticky_controls.dart';
import '../../widgets/mini_equalizer.dart';
import '../shared/mini_progress_bar.dart';

class ArtistDetailView extends StatelessWidget {
  final String artistName;

  const ArtistDetailView({
    super.key,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context) {
    final playlistVM = context.watch<PlaylistViewModel>();

    // 🎶 músicas do artista
    final musics = playlistVM.musics
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
          // 🎬 HEADER CINEMATOGRÁFICO
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
                    // 🎨 FUNDO
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.95),
                            Colors.black,
                          ],
                        ),
                      ),
                    ),

                    // 🌫 BLUR
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: Colors.black.withOpacity(0.25),
                      ),
                    ),

                    // 🎤 CONTEÚDO CENTRAL
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: color.withOpacity(0.3),
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
                            '${musics.length} músicas',
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

          // 🔥 STICKY CONTROLS
          SliverPersistentHeader(
            pinned: true,
            delegate: CollectionStickyControls(
              musics: musics,
              color: color,
            ),
          ),

          // 🎵 LISTA DE MÚSICAS
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: musics.length,
              (context, index) {
                final music = musics[index];

                return ListTile(
                  leading: Consumer<PlaylistViewModel>(
                    builder: (context, vm, _) {
                      final isCurrent =
                          vm.currentMusic?.id == music.id;

                      if (!isCurrent) {
                        return const Icon(Icons.music_note);
                      }

                      return MiniEqualizer(
                        isPlaying: vm.isPlaying,
                        color: color,
                        size: 22,
                      );
                    },
                  ),
                  title: Text(music.title),
                  subtitle: Consumer<PlaylistViewModel>(
                    builder: (context, vm, _) {
                      final isCurrent =
                          vm.currentMusic?.id == music.id;

                      if (!isCurrent) {
                        return Text(music.album ?? '');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(music.album ?? ''),
                          StreamBuilder<Duration>(
                            stream: vm.positionStream,
                            builder: (context, snapshot) {
                              final position =
                                  snapshot.data ?? Duration.zero;
                              final duration =
                                  vm.player.duration ?? Duration.zero;

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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlayerView(),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
