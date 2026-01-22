import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/music_entity.dart';
import '../playlist/playlist_view_model.dart';
import '../player/player_view.dart';
import '../player/mini_player_view.dart';
import 'favorite_empty_state.dart';


class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  String _formatDuration(int? duration) {
    if (duration == null) return "00:00";
    final m = duration ~/ 60000;
    final s = (duration % 60000) ~/ 1000;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistViewModel>().loadFavoriteMusics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<PlaylistViewModel>();
    final musics = viewModel.favoriteMusics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritas ❤️'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
  IconButton(
    icon: Icon(
      viewModel.favoriteOrder == FavoriteOrder.az
          ? Icons.sort_by_alpha
          : Icons.schedule,
    ),
    tooltip: viewModel.favoriteOrder == FavoriteOrder.az
        ? 'Ordenar A–Z'
        : 'Mais recentes',
    onPressed: viewModel.toggleFavoriteOrder,
  ),
],

      ),
      body: musics.isEmpty
    ? const FavoriteEmptyState()
    : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: musics.length,
              itemBuilder: (context, index) {
                final music = musics[index];
                final isPlaying =
                    viewModel.currentMusic?.id == music.id;

                return ListTile(
                  leading: const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    music.title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    music.artist,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: isPlaying
                      ? Icon(
                          Icons.equalizer,
                          color: theme.colorScheme.primary,
                        )
                      : Text(
                          _formatDuration(music.duration),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                  onTap: () {
                    viewModel.playMusic(musics, index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlayerView(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (viewModel.currentMusic != null)
            const MiniPlayerView(),
        ],
      ),

    );

    
  }
  Widget _buildEmptyState(BuildContext context) {
  final theme = Theme.of(context);

  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma música favorita ainda',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Toque no ❤️ enquanto escuta uma música para adicioná-la aqui.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

}
