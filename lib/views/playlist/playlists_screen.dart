// lib/views/playlist/playlists_screen.dart

import 'package:flutter/material.dart';
import 'package:music_music/delegates/music_search_delegate.dart';
import 'package:music_music/views/playlist/playlist_detail_screen.dart';
import 'package:provider/provider.dart';
import '../playlist/playlist_view_model.dart';

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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                  _playlistsFuture =
                      viewModel.getPlaylistsWithMusicCount();
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
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja apagar a playlist "$playlistName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deletePlaylist(playlistId);
              setState(() {
                _playlistsFuture =
                    viewModel.getPlaylistsWithMusicCount();
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                _showCreatePlaylistDialog(context, viewModel),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
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
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          final playlists = snapshot.data ?? [];

          if (playlists.isEmpty) {
            return const Center(
              child: Text('Você ainda não criou nenhuma playlist.'),
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
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                        '$count ${count == 1 ? 'música' : 'músicas'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _showDeleteConfirmationDialog(
                          context,
                          viewModel,
                          id,
                          name,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(
                              playlistId: id,
                              playlistName: name,
                            ),
                          ),
                        );
                      },
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
