import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/music_model.dart';
import '../playlist/music_selection_screen.dart';
import '../playlist/playlist_view_model.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName, required List<Music> musics,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late Future<List<Music>> _musicsFuture;

  @override
  void initState() {
    super.initState();
    _musicsFuture = _loadMusics();
  }

  Future<List<Music>> _loadMusics() {
    return Provider.of<PlaylistViewModel>(context, listen: false)
        .getMusicsFromPlaylist(widget.playlistId);
  }

  // Método para remover a música e atualizar a tela
  void _removeMusic(int musicId) {
    // Chama o método do ViewModel para remover a música
    Provider.of<PlaylistViewModel>(context, listen: false)
        .removeMusicFromPlaylist(widget.playlistId, musicId);

    // Exibe um SnackBar de confirmação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Música removida da playlist.'),
        duration: Duration(seconds: 2),
      ),
    );

    // Recarrega a lista para atualizar a UI
    setState(() {
      _musicsFuture = _loadMusics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Color(0xFF13101E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Music>>(
          future: _musicsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accentPurple));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }
            final musics = snapshot.data ?? [];
            if (musics.isEmpty) {
              return const Center(
                child: Text(
                  'Esta playlist não tem músicas.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: musics.length,
              itemBuilder: (context, index) {
                final music = musics[index];
                return Card(
                  color: AppColors.cardBackground,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.lightPurple,
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      music.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      music.artist,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    // Botão de remoção na direita
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever,
                          color: Colors.redAccent),
                      onPressed: () {
                        _removeMusic(music.id);
                      },
                    ),
                    onTap: () {
                      Provider.of<PlaylistViewModel>(context, listen: false)
                          .playMusic(index);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MusicSelectionScreen(
                playlistId: widget.playlistId,
                playlistName: widget.playlistName,
              ),
            ),
          );
          // Recarregar a lista de músicas quando retornar
          setState(() {
            _musicsFuture = _loadMusics();
          });
        },
        backgroundColor: AppColors.accentPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
