import 'package:flutter/material.dart';
import 'package:music_music/views/playlist/playlist_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/theme/app_colors.dart';
import '../playlist/playlist_view_model.dart';
import '../../models/music_model.dart';


class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Playlists'),
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
        child: Consumer<PlaylistViewModel>(
          builder: (context, viewModel, child) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: viewModel.getPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accentPurple));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar playlists: ${snapshot.error}'));
                }
                final playlists = snapshot.data ?? [];
                if (playlists.isEmpty) {
                  return const Center(
                    child: Text(
                      'Você ainda não criou nenhuma playlist.',
                      style: TextStyle(color: Colors.white70),
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
                    
                    return Card(
                      color: AppColors.cardBackground,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      child: ListTile(
                        leading: const Icon(Icons.queue_music, color: AppColors.accentPurple),
                        title: Text(
                          playlistName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onTap: () async {
                          final musics = await viewModel.getMusicsFromPlaylist(playlistId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistDetailScreen(
                                playlistId: playlistId,
                                playlistName: playlistName,
                                musics: musics,
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
