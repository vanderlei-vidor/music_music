import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/core/ui/genre_colors.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/app/routes.dart';

import 'package:music_music/shared/widgets/collection_sticky_controls.dart';
import 'package:music_music/shared/widgets/mini_progress_bar.dart';
import 'package:music_music/shared/widgets/mini_equalizer.dart';
import 'package:music_music/shared/widgets/skeleton.dart';

class GenreDetailView extends StatefulWidget {
  final String genre;
  final List<MusicEntity> musics;

  const GenreDetailView({
    super.key,
    required this.genre,
    required this.musics,
  });

  @override
  State<GenreDetailView> createState() => _GenreDetailViewState();
}

class _GenreDetailViewState extends State<GenreDetailView> {
  final Map<int, GlobalKey> _itemKeys = {};
  final ValueNotifier<List<MusicEntity>> _musicsNotifier =
      ValueNotifier<List<MusicEntity>>(<MusicEntity>[]);

  @override
  void dispose() {
    _musicsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeGenre = widget.musics.firstOrNull?.genre;

    final color = GenreColorHelper.getColor(
      safeGenre?.isNotEmpty == true ? safeGenre! : widget.genre,
    );

    // Escuta APENAS troca da musica atual
    context.select<PlaylistViewModel, int?>(
      (vm) => vm.currentMusic?.id,
    );

    // Scroll automatico seguro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToCurrentMusic(context);
    });

    _musicsNotifier.value = widget.musics;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // HEADER
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Hero(
                tag: 'genre_${widget.genre}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withOpacity(0.95), Colors.black],
                        ),
                      ),
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.black.withOpacity(0.25)),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.music_note,
                            size: 64,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${widget.musics.length} músicas',
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

          // CONTROLES FIXOS
          SliverPersistentHeader(
            pinned: true,
            delegate: CollectionStickyControls(
              musics: widget.musics,
              color: color,
            ),
          ),

          // LISTA DE MUSICAS
          ValueListenableBuilder<List<MusicEntity>>(
            valueListenable: _musicsNotifier,
            builder: (_, musics, __) {
              if (musics.isEmpty) {
                return const SliverToBoxAdapter(child: _DetailListSkeleton());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final music = musics[index];

                    _itemKeys.putIfAbsent(music.id!, () => GlobalKey());

                    return Container(
                      key: _itemKeys[music.id],
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
                              return Text(music.artist);
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(music.artist),
                                const SizedBox(height: 4),
                                StreamBuilder<Duration>(
                                  stream: context
                                      .read<PlaylistViewModel>()
                                      .positionStream,
                                  builder: (_, snapshot) {
                                    final position =
                                        snapshot.data ?? Duration.zero;
                                    final duration = context
                                            .read<PlaylistViewModel>()
                                            .player
                                            .duration ??
                                        Duration.zero;

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
                          final vm = context.read<PlaylistViewModel>();
                          await vm.playMusic(musics, index);

                          if (mounted) {
                            Navigator.pushNamed(context, AppRoutes.player);
                          }
                        },
                      ),
                    );
                  },
                  childCount: musics.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===============================
  // SCROLL PREMIUM
  // ===============================
  void _scrollToCurrentMusic(BuildContext context) {
    final vm = context.read<PlaylistViewModel>();
    final currentId = vm.currentMusic?.id;

    if (currentId == null) return;

    final key = _itemKeys[currentId];
    if (key == null) return;

    final ctx = key.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.3,
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

class _DetailListSkeleton extends StatelessWidget {
  const _DetailListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          8,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Skeleton(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: double.infinity, height: 12),
                      SizedBox(height: 8),
                      Skeleton(width: 140, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
