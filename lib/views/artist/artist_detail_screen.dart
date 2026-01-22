import 'package:flutter/material.dart';
import 'package:music_music/models/music_entity.dart';
import 'package:music_music/views/player/player_view.dart';
import 'package:music_music/views/playlist/playlist_view_model.dart';
import 'package:provider/provider.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;

  const ArtistDetailScreen({
    super.key,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context) {
    final playlistVM = context.read<PlaylistViewModel>();

    // 🔥 pega TODAS músicas já carregadas
    final allMusics = playlistVM.musics;


    final artistMusics = allMusics
        .where((m) => m.artist.toLowerCase() == artistName.toLowerCase())
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(artistName),
      ),
      body: Column(
        children: [
          // 🎤 HEADER DO ARTISTA
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 48,
                  child: Icon(Icons.person, size: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  artistName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${artistMusics.length} músicas',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // ▶️ TOCAR TUDO
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Tocar tudo'),
                  onPressed: () async {
                    await playlistVM.playMusic(artistMusics, 0);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlayerView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // 🎵 LISTA
          Expanded(
            child: ListView.builder(
              itemCount: artistMusics.length,
              itemBuilder: (_, index) {
                final music = artistMusics[index];

                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(music.title),
                  subtitle: Text(music.album ?? ''),
                  onTap: () async {
                    await playlistVM.playMusic(artistMusics, index);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlayerView()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
