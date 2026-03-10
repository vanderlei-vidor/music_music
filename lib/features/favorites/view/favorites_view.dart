import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/features/playlists/models/favorite_order.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/features/player/view/mini_player_view.dart';
import 'package:music_music/shared/widgets/app_state_view.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  bool _isLoadingFavorites = true;
  String? _loadError;

  String _formatDuration(int? duration) {
    if (duration == null) return '00:00';
    final m = duration ~/ 60000;
    final s = (duration % 60000) ~/ 1000;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoadingFavorites = true;
      _loadError = null;
    });

    try {
      await context.read<PlaylistViewModel>().loadFavoriteMusics();
    } catch (e) {
      _loadError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorites = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<PlaylistViewModel>();
    final musics = viewModel.favoriteMusics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritas'),
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
                ? 'Ordenar A-Z'
                : 'Mais recentes',
            onPressed: viewModel.toggleFavoriteOrder,
          ),
        ],
      ),
      body: _isLoadingFavorites
          ? const AppStateView.loading(
              title: 'Carregando favoritas',
              subtitle: 'Buscando as musicas que voce marcou com coracao.',
            )
          : _loadError != null
              ? AppStateView.error(
                  title: 'Nao foi possivel carregar favoritas',
                  subtitle: _loadError!,
                  actionLabel: 'Tentar novamente',
                  onAction: _loadFavorites,
                )
              : musics.isEmpty
                  ? AppStateView.empty(
                      icon: Icons.favorite_border_rounded,
                      title: 'Nenhuma favorita ainda',
                      subtitle:
                          'Marque musicas com coracao para aparecerem aqui.',
                    )
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
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                                  color:
                                      theme.colorScheme.onSurface.withValues(alpha: 
                                        0.7,
                                      ),
                                ),
                              ),
                        onTap: () {
                          viewModel.playMusic(musics, index);
                          Navigator.pushNamed(context, AppRoutes.player);
                        },
                      );
                    },
                  ),
                ),
                if (viewModel.currentMusic != null) const MiniPlayerView(),
              ],
            ),
    );
  }
}

