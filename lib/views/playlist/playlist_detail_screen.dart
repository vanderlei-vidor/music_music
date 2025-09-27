// lib/views/playlist/playlist_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
// Remova esta linha:
// import '../../core/theme/app_colors.dart';
import '../../models/music_model.dart';
import '../player/mini_player_view.dart';
import '../player/player_view.dart';
import '../playlist/music_selection_screen.dart';
import '../playlist/playlist_view_model.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState; // 👈 necessário para PlayerState

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
  late Future<List<Music>> _musicsFuture;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Music> _allMusics = [];
  List<Music> _filteredMusics = [];

  @override
  void initState() {
    super.initState();
    _musicsFuture = _loadMusics().then((musics) {
      setState(() {
        _allMusics = musics;
        _filteredMusics = musics;
      });
      return musics;
    });

    _searchController.addListener(_filterMusics);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Music>> _loadMusics() {
    return context
        .read<PlaylistViewModel>()
        .getMusicsFromPlaylist(widget.playlistId);
  }

  void _filterMusics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMusics = _allMusics;
      } else {
        _filteredMusics = _allMusics.where((music) {
          return music.title.toLowerCase().contains(query) ||
              (music.artist?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  void _removeMusic(int musicId) {
    context
        .read<PlaylistViewModel>()
        .removeMusicFromPlaylist(widget.playlistId, musicId);

    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Música removida da playlist.',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.snackBarTheme.backgroundColor ?? theme.colorScheme.surface,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      _musicsFuture = _loadMusics().then((musics) {
        setState(() {
          _allMusics = musics;
          _filteredMusics = musics;
        });
        return musics;
      });
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
    final theme = Theme.of(context);
    final viewModel = context.watch<PlaylistViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar músicas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18),
              )
            : Text(widget.playlistName),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: theme.colorScheme.onSurface),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredMusics = _allMusics;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
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
                _musicsFuture = _loadMusics().then((musics) {
                  setState(() {
                    _allMusics = musics;
                    _filteredMusics = musics;
                  });
                  return musics;
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
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
              child: FutureBuilder<List<Music>>(
                future: _musicsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro: ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                    );
                  }
                  final musicsToShow = _isSearching ? _filteredMusics : snapshot.data ?? [];
                  if (musicsToShow.isEmpty) {
                    return Center(
                      child: Text(
                        'Esta playlist não tem músicas.',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                    );
                  }
                  return Consumer<PlaylistViewModel>(
                    builder: (context, viewModel, child) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: musicsToShow.length,
                        itemBuilder: (context, index) {
                          final music = musicsToShow[index];
                          final isPlaying = viewModel.currentMusic?.id == music.id;

                          return Card(
                            color: theme.cardColor,
                            margin: const EdgeInsets.only(bottom: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: isPlaying
                                  ? BorderSide(color: theme.colorScheme.primary, width: 2)
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
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              title: Text(
                                music.title,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                music.artist ?? "Artista desconhecido",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              trailing: isPlaying
                                  ? IconButton(
                                      icon: Icon(
                                        viewModel.playerState == PlayerState.playing
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color: theme.colorScheme.primary,
                                        size: 40,
                                      ),
                                      onPressed: viewModel.playPause,
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete_forever),
                                      color: Colors.redAccent, // Pode manter vermelho aqui (universal)
                                      onPressed: () {
                                        _removeMusic(music.id);
                                      },
                                    ),
                              onTap: () {
                                if (isPlaying) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PlayerView(),
                                    ),
                                  );
                                } else {
                                  final originalIndex = _allMusics.indexOf(music);
                                  if (originalIndex != -1) {
                                    viewModel.playMusic(_allMusics, originalIndex);
                                  }
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
    );
  }
}