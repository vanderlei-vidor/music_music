
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';




class MostPlayedView extends StatefulWidget {
  const MostPlayedView({super.key});

  @override
  State<MostPlayedView> createState() => _MostPlayedViewState();
}

class _MostPlayedViewState extends State<MostPlayedView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistViewModel>().loadMostPlayed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlaylistViewModel>();
    final musics = vm.mostPlayed;

    return Scaffold(
      appBar: AppBar(title: const Text('🔥 Mais tocadas')),
      body: musics.isEmpty
          ? const Center(child: Text('Ainda não há dados'))
          : ListView.builder(
              itemCount: musics.length,
              itemBuilder: (_, i) {
                final music = musics[i];

                return ListTile(
                  leading: _rankIcon(i),
                  title: Text(music.title),
                  subtitle: Text(music.artist),
                  trailing: Text('${music.playCount} ▶'),
                  onTap: () => vm.playMusic(musics, i),
                );
              },
            ),
    );
  }

  Widget _rankIcon(int index) {
    if (index == 0) return const Icon(Icons.emoji_events, color: Colors.amber);
    if (index == 1) return const Icon(Icons.emoji_events, color: Colors.grey);
    if (index == 2) return const Icon(Icons.emoji_events, color: Colors.brown);
    return Text('${index + 1}');
  }
}

