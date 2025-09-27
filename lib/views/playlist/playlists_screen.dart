// lib/views/playlist/playlists_screen.dart

import 'package:flutter/material.dart';
import 'package:music_music/delegates/music_search_delegate.dart';
import 'package:music_music/views/playlist/playlist_detail_screen.dart';
import 'package:provider/provider.dart';
// Remova esta linha:
// import '../../core/theme/app_colors.dart';
import '../playlist/playlist_view_model.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  void _showCreatePlaylistDialog(BuildContext context, PlaylistViewModel viewModel) {
  final theme = Theme.of(context);
  final TextEditingController controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text('Criar Nova Playlist', style: TextStyle(color: theme.colorScheme.onSurface)),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Nome da Playlist',
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
        ),
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.onSurface)),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              viewModel.createPlaylist(controller.text);
              Navigator.pop(context);
            }
          },
          child: Text('Criar', style: TextStyle(color: theme.colorScheme.primary)),
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
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text('Confirmar Exclusão', style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text(
            'Tem certeza que deseja apagar a playlist "$playlistName"?',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Não', style: TextStyle(color: theme.colorScheme.onSurface)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Sim', style: TextStyle(color: theme.colorScheme.error)),
              onPressed: () {
                viewModel.deletePlaylist(playlistId);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playlist "$playlistName" removida.'),
                    backgroundColor: theme.colorScheme.error,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Playlists', style: TextStyle(color: theme.colorScheme.onSurface)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
    icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
    onPressed: () => Navigator.pop(context),
  ),
  actions: [
    // ✅ Botão de CRIAR NOVA PLAYLIST
    IconButton(
      icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
      tooltip: 'Criar nova playlist',
      onPressed: () {
        _showCreatePlaylistDialog(context, Provider.of<PlaylistViewModel>(context, listen: false));
        
      },
    ),
    // ✅ Botão de busca
    //IconButton(
    //  icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
     // onPressed: () {
      //  final viewModel = Provider.of<PlaylistViewModel>(context, listen: false);
      //  showSearch(
       //   context: context,
       //   delegate: MusicSearchDelegate(viewModel.musics),
       // );
    //  },
   // ),
  ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              theme.brightness == Brightness.dark
                  ? const Color(0xFF13101E)
                  : theme.scaffoldBackgroundColor.withOpacity(0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<PlaylistViewModel>(
          builder: (context, viewModel, child) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: viewModel.getPlaylistsWithMusicCount(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar playlists: ${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  );
                }
                final playlists = snapshot.data ?? [];
                if (playlists.isEmpty) {
                  return Center(
                    child: Text(
                      'Você ainda não criou nenhuma playlist.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final playlistId = playlist['id'] as int;
                    final playlistName = playlist['name'] as String;
                    final musicCount = playlist['musicCount'] as int;

                    return Card(
                      color: theme.cardColor,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.queue_music,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          playlistName,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$musicCount ${musicCount == 1 ? 'música' : 'músicas'}',
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          color: theme.colorScheme.error,
                          onPressed: () {
                            _showDeleteConfirmationDialog(
                              context,
                              viewModel,
                              playlistId,
                              playlistName,
                            );
                          },
                        ),
                        onTap: () async {
                          final musics = await viewModel.getMusicsFromPlaylist(playlistId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistDetailScreen(
                                playlistId: playlistId,
                                playlistName: playlistName,
                                // Remova o parâmetro 'musics' se o construtor não o aceitar mais
                                // (você removeu ele no código anterior, então provavelmente não é mais necessário)
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}