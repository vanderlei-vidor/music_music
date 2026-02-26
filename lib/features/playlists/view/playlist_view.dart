import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:music_music/app/routes.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/delegates/music_search_delegate.dart';
import 'package:music_music/features/player/view/mini_player_view.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Criar nova playlist',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nome da playlist',
            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              viewModel.createPlaylist(controller.text.trim());
              Navigator.pop(context);
            },
            child: Text(
              'Criar',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Musicas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
            tooltip: 'Criar nova playlist',
            onPressed: () {
              _showCreatePlaylistDialog(
                context,
                context.read<PlaylistViewModel>(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
            onPressed: () {
              final viewModel = context.read<PlaylistViewModel>();
              showSearch(
                context: context,
                delegate: MusicSearchDelegate(viewModel.libraryMusics),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, _) {
          final musics = viewModel.libraryMusics;
          if (musics.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: musics.length,
                  itemBuilder: (context, index) {
                    final music = musics[index];

                    return Dismissible(
                      key: ValueKey(music.id ?? music.audioUrl),
                      direction: DismissDirection.horizontal,
                      background: _swipeFavoriteBackground(
                        isFavorite: music.isFavorite,
                        theme: theme,
                        isLeft: true,
                      ),
                      secondaryBackground: _swipeFavoriteBackground(
                        isFavorite: music.isFavorite,
                        theme: theme,
                        isLeft: false,
                      ),
                      confirmDismiss: (_) async {
                        HapticFeedback.lightImpact();
                        await context.read<PlaylistViewModel>().toggleFavorite(music);
                        return false;
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _PressableTile(
                          onTap: () {
                            final vm = context.read<PlaylistViewModel>();
                            vm.playMusic(vm.libraryMusics, index);
                          },
                          onDoubleTap: () {
                            Navigator.pushNamed(context, AppRoutes.player);
                          },
                          child: _musicTile(context, theme, music),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (viewModel.currentMusic != null) const MiniPlayerView(),
            ],
          );
        },
      ),
    );
  }

  Widget _swipeFavoriteBackground({
    required bool isFavorite,
    required ThemeData theme,
    required bool isLeft,
  }) {
    return Container(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isFavorite ? Colors.grey.shade800 : Colors.redAccent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        isFavorite ? Icons.favorite_border : Icons.favorite,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _musicTile(BuildContext context, ThemeData theme, MusicEntity music) {
    return Selector<PlaylistViewModel, _NowPlayingState>(
      selector: (_, vm) => _NowPlayingState(
        id: vm.currentMusic?.id,
        isPlaying: vm.isPlaying,
      ),
      builder: (_, state, __) {
        final isPlaying = state.id == music.id;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            border: isPlaying
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            leading: Icon(
              Icons.music_note,
              color: isPlaying
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(music.title),
            subtitle: Text(music.artist),
            trailing: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: music.isFavorite
                  ? const Icon(
                      Icons.favorite,
                      key: ValueKey('fav_on'),
                      color: Colors.redAccent,
                    )
                  : const Icon(
                      Icons.favorite_border,
                      key: ValueKey('fav_off'),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const _PressableTile({
    required this.child,
    required this.onTap,
    this.onDoubleTap,
  });

  @override
  State<_PressableTile> createState() => _PressableTileState();
}

class _PressableTileState extends State<_PressableTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
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
    return other is _NowPlayingState &&
        other.id == id &&
        other.isPlaying == isPlaying;
  }

  @override
  int get hashCode => Object.hash(id, isPlaying);
}
