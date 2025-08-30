import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/music_model.dart';
import '../player/mini_player_view.dart';
import '../player/player_view.dart';
import '../playlist/music_selection_screen.dart';
import '../playlist/playlist_view_model.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
    required List<Music> musics,
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
    return context.read<PlaylistViewModel>()
        .getMusicsFromPlaylist(widget.playlistId);
  }

  void _removeMusic(int musicId) {
    context.read<PlaylistViewModel>()
        .removeMusicFromPlaylist(widget.playlistId, musicId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Música removida da playlist.'),
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {
      _musicsFuture = _loadMusics();
    });
  }

  String _formatDuration(int? duration) {
    if (duration == null) return "00:00";
    final minutes = (duration / 60000).truncate();
    final seconds = ((duration % 60000) / 1000).truncate();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PlaylistViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
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
                        child: CircularProgressIndicator(
                            color: AppColors.accentPurple));
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
                  return Consumer<PlaylistViewModel>(
                    builder: (context, viewModel, child) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: musics.length,
                        itemBuilder: (context, index) {
                          final music = musics[index];
                          final isPlaying = viewModel.currentMusic?.id == music.id;

                          return Card(
                            color: AppColors.cardBackground,
                            margin: const EdgeInsets.only(bottom: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: isPlaying
                                  ? const BorderSide(
                                      color: AppColors.accentPurple, width: 2)
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              leading: QueryArtworkWidget(
                                id: music.albumId ?? 0,
                                type: ArtworkType.ALBUM,
                                artworkBorder: BorderRadius.circular(10),
                                nullArtworkWidget: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.music_note,
                                      color: Colors.white),
                                ),
                              ),
                              title: Text(
                                music.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                music.artist,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: isPlaying
                                  ? IconButton(
                                      icon: Icon(
                                        viewModel.playerState ==
                                                PlayerState.playing
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color: AppColors.accentPurple,
                                        size: 40,
                                      ),
                                      onPressed: viewModel.playPause,
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete_forever,
                                          color: Colors.redAccent),
                                      onPressed: () {
                                        _removeMusic(music.id);
                                      },
                                    ),
                              onTap: () {
                                if (isPlaying) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const PlayerView()),
                                  );
                                } else {
                                  // Define a lista de reprodução atual e toca a música
                                  viewModel.playMusic(musics, index);
                                }
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
          ),
          if (viewModel.currentMusic != null) const MiniPlayerView(),
        ],
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
