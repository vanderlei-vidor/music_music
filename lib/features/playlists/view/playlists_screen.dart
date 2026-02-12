// lib/views/playlist/playlists_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_music/delegates/music_search_delegate.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:provider/provider.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/skeleton.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  late Future<List<Map<String, dynamic>>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    final vm = context.read<PlaylistViewModel>();
    _playlistsFuture = vm.getPlaylistsWithMusicCount();
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Criar Nova Playlist',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nome da Playlist',
            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                viewModel.createPlaylist(controller.text);
                setState(() {
                  _playlistsFuture = viewModel.getPlaylistsWithMusicCount();
                });
                Navigator.pop(context);
              }
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

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    PlaylistViewModel viewModel,
    int playlistId,
    String playlistName,
  ) async {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text('Confirmar ExclusÃ£o'),
        content: Text(
          'Tem certeza que deseja apagar a playlist "$playlistName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NÃ£o'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deletePlaylist(playlistId);
              setState(() {
                _playlistsFuture = viewModel.getPlaylistsWithMusicCount();
              });
              Navigator.pop(context);
            },
            child: Text(
              'Sim',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.read<PlaylistViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Playlists'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              HapticFeedback.selectionClick();
              _showCreatePlaylistDialog(context, viewModel);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              HapticFeedback.selectionClick();
              showSearch(
                context: context,
                delegate: MusicSearchDelegate(viewModel.musics),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _PlaylistsSkeleton();
          }

          final playlists = snapshot.data ?? [];

          if (playlists.isEmpty) {
            return const Center(
              child: Text('VocÃª ainda nÃ£o criou nenhuma playlist.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final id = playlist['id'] as int;
              final name = playlist['name'] as String;
              final count = playlist['musicCount'] as int;
              final shadows =
                  Theme.of(context).extension<AppShadows>()?.elevated ?? [];

              return Hero(
                tag: 'playlist_$id',
                flightShuttleBuilder:
                    (context, animation, direction, from, to) {
                  return Material(
                    color: Colors.transparent,
                    child: to.widget,
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: _PressableTile(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pushNamed(
                        context,
                        AppRoutes.playlistDetail,
                        arguments: PlaylistDetailArgs(
                          playlistId: id,
                          playlistName: name,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: shadows,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.queue_music),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$count ${count == 1 ? 'mÃºsica' : 'mÃºsicas'}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _showDeleteConfirmationDialog(
                              context,
                              viewModel,
                              id,
                              name,
                            );
                          },
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
    );
  }
}

class _PlaylistsSkeleton extends StatelessWidget {
  const _PlaylistsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: const [
              Skeleton(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(10))),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    Skeleton(width: 120, height: 12),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Skeleton(width: 28, height: 28, borderRadius: BorderRadius.all(Radius.circular(8))),
            ],
          ),
        );
      },
    );
  }
}

class _PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableTile({
    required this.child,
    required this.onTap,
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

