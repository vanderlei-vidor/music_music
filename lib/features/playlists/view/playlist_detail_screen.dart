// lib/views/playlist/playlist_detail_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:music_music/shared/widgets/playlist_sticky_controls.dart';
import 'package:music_music/shared/widgets/swipe_to_reveal_actions.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/app/routes.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late Future<List<MusicEntity>> _musicsFuture;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<MusicEntity> _allMusics = [];
  List<MusicEntity> _filteredMusics = [];

  @override
  void initState() {
    super.initState();
    _reloadMusics();
    _searchController.addListener(_filterMusics);
  }

  @override
  void didUpdateWidget(covariant PlaylistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.playlistId != widget.playlistId) {
      _reloadMusics();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadMusics() {
    _musicsFuture = context
        .read<PlaylistViewModel>()
        .getMusicsFromPlaylistV2(widget.playlistId)
        .then((musics) {
          setState(() {
            _allMusics = musics;
            _filteredMusics = musics;
          });
          return musics;
        });
  }

  void _filterMusics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMusics = _allMusics;
      } else {
        _filteredMusics = _allMusics.where((music) {
          return music.title.toLowerCase().contains(query) ||
              music.artist.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _removeMusic(int musicId) {
    context.read<PlaylistViewModel>().removeMusicFromPlaylist(
      widget.playlistId,
      musicId,
    );

    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Música removida da playlist.',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor:
            theme.snackBarTheme.backgroundColor ?? theme.colorScheme.surface,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(_reloadMusics);
  }

  String _formatDuration(int? duration) {
    if (duration == null) return "00:00";
    final minutes = (duration ~/ 60000);
    final seconds = ((duration % 60000) ~/ 1000);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<PlaylistViewModel>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add music'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: () async {
          await Navigator.pushNamed(
            context,
            AppRoutes.musicSelection,
            arguments: MusicSelectionArgs(
              playlistId: widget.playlistId,
              playlistName: widget.playlistName,
            ),
          );
          _reloadMusics();
        },
      ),
      body: CustomScrollView(
        slivers: [
          // 🧠 HEADER GRANDE
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Hero(
                tag: 'playlist_${widget.playlistId}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    widget.playlistName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              background: _buildHeaderBackground(theme),
            ),
          ),

          // 🎮 CONTROLES STICKY (GRUDAM NO TOPO)
          SliverPersistentHeader(
            pinned: true,
            delegate: PlaylistStickyControls(),
          ),

          // 🎵 LISTA
          _buildMusicSliverList(theme, viewModel),
        ],
      ),
    );
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

  SliverAppBar _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,

      actions: [],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Hero(
          tag: 'playlist_${widget.playlistId}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              widget.playlistName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 🎨 BACKGROUND
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.9),
                    theme.scaffoldBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 🌫 BLUR
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withOpacity(0.10)),
              ),
            ),

            // 🎶 CONTEÚDO
          ],
        ),
      ),
    );
  }

  Widget _buildMusicSliverList(ThemeData theme, PlaylistViewModel viewModel) {
    final musics = _isSearching ? _filteredMusics : _allMusics;

    if (musics.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.queue_music,
                size: 72,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Esta playlist ainda está vazia',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Adicione músicas para começar a curtir 🎧',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              /// 🔥 BOTÃO DE AÇÃO
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Adicionar músicas'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.musicSelection,
                    arguments: MusicSelectionArgs(
                      playlistId: widget.playlistId,
                      playlistName: widget.playlistName,
                    ),
                  );
                  setState(_reloadMusics);
                },
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 96),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final music = musics[index];
          final isPlaying = viewModel.currentMusic?.id == music.id;

          final shadows =
              Theme.of(context).extension<AppShadows>()?.surface ?? [];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SwipeToRevealActions(
              isFavorite: music.isFavorite,
              onToggleFavorite: () async {
                final vm = context.read<PlaylistViewModel>();

                final newValue = await vm.toggleFavorite(music);

                setState(() {
                  final index = _allMusics.indexWhere((m) => m.id == music.id);
                  if (index != -1) {
                    _allMusics[index] = _allMusics[index].copyWith(
                      isFavorite: newValue,
                    );
                  }

                  final filteredIndex = _filteredMusics.indexWhere(
                    (m) => m.id == music.id,
                  );
                  if (filteredIndex != -1) {
                    _filteredMusics[filteredIndex] =
                        _filteredMusics[filteredIndex].copyWith(
                          isFavorite: newValue,
                        );
                  }
                });
              },

              onDelete: () {
                final musicId = music.id;
                if (musicId == null) return;

                context.read<PlaylistViewModel>().removeMusicFromPlaylist(
                  widget.playlistId,
                  musicId,
                );

                setState(() {
                  _allMusics.removeWhere((m) => m.id == musicId);
                  _filteredMusics.removeWhere((m) => m.id == musicId);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Música removida da playlist'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },

              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: shadows,
                ),
                child: ListTile(
                  title: Text(music.title),
                  subtitle: Text(music.artist),
                  trailing: viewModel.currentMusic?.id == music.id
                      ? Icon(Icons.equalizer, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    if (viewModel.isShuffled) {
                      final shuffled = List<MusicEntity>.from(_allMusics)
                        ..shuffle();
                      viewModel.playMusic(shuffled, 0);
                    } else {
                      viewModel.playMusic(_allMusics, index);
                    }
                  },
                ),
              ),
            ),
          );
        }, childCount: musics.length),
      ),
    );
  }

  Widget _buildHeaderBackground(ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.9),
                theme.scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withOpacity(0.10)),
          ),
        ),
      ],
    );
  }
}




