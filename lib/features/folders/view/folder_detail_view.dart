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

class FolderDetailView extends StatefulWidget {
  final String folderName;
  final List<MusicEntity> musics;

  const FolderDetailView({
    super.key,
    required this.folderName,
    required this.musics,
  });

  @override
  State<FolderDetailView> createState() => _FolderDetailViewState();
}

class _FolderDetailViewState extends State<FolderDetailView> {
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  Widget build(BuildContext context) {
    final safeGenre = widget.musics.isNotEmpty &&
            widget.musics.first.genre != null &&
            widget.musics.first.genre!.isNotEmpty
        ? widget.musics.first.genre!
        : widget.folderName;

    final color = GenreColorHelper.getColor(safeGenre);

    // 🔑 escuta APENAS troca da música atual
    context.select<PlaylistViewModel, int?>(
      (vm) => vm.currentMusic?.id,
    );

    // 🔁 scroll automático seguro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToCurrentMusic(context);
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 🎬 HEADER CINEMATOGRÁFICO
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.folderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Hero(
                tag: 'folder_${widget.folderName}_detail',
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

          // 🔥 CONTROLES FIXOS
          SliverPersistentHeader(
            pinned: true,
            delegate: CollectionStickyControls(
              musics: widget.musics,
              color: color,
            ),
          ),

          // 🎵 LISTA DE MÚSICAS
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final music = widget.musics[index];

                _itemKeys.putIfAbsent(music.id!, () => GlobalKey());

                return Container(
                  key: _itemKeys[music.id],
                  child: ListTile(
                    leading: Consumer<PlaylistViewModel>(
                      builder: (_, vm, __) {
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
                      builder: (_, vm, __) {
                        final isCurrent =
                            vm.currentMusic?.id == music.id;

                        if (!isCurrent) {
                          return Text(music.artist);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(music.artist),
                            const SizedBox(height: 4),
                            StreamBuilder<Duration>(
                              stream: vm.positionStream,
                              builder: (_, snapshot) {
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
                      final vm = context.read<PlaylistViewModel>();
                      await vm.playMusic(widget.musics, index);

                      if (mounted) {
                        Navigator.pushNamed(context, AppRoutes.player);
                      }
                    },
                  ),
                );
              },
              childCount: widget.musics.length,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // 🎯 SCROLL AUTOMÁTICO PREMIUM
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




