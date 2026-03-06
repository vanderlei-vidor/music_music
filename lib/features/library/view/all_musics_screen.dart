import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:music_music/app/routes.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/features/player/view/mini_player_view.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/app_state_view.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';
import 'package:music_music/shared/widgets/swipe_to_reveal_actions.dart';

class AllMusicsScreen extends StatefulWidget {
  const AllMusicsScreen({super.key});

  @override
  State<AllMusicsScreen> createState() => _AllMusicsScreenState();
}

class _AllMusicsScreenState extends State<AllMusicsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _QuickFilter _quickFilter = _QuickFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MusicEntity> _filterMusics(
    List<MusicEntity> musics,
    PlaylistViewModel playerVM,
  ) {
    final favorites = playerVM.favoriteMusics.map((m) => m.audioUrl).toSet();
    final recent = playerVM.recentMusics.map((m) => m.audioUrl).toSet();

    var filtered = musics;
    if (_quickFilter == _QuickFilter.favorites) {
      filtered = musics.where((m) => favorites.contains(m.audioUrl)).toList();
    } else if (_quickFilter == _QuickFilter.recent) {
      filtered = musics.where((m) => recent.contains(m.audioUrl)).toList();
    }

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return filtered;
    return filtered.where((music) {
      final title = music.title.toLowerCase();
      final artist = music.artist.toLowerCase();
      final album = (music.album ?? '').toLowerCase();
      return title.contains(q) || artist.contains(q) || album.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Todas as musicas'), centerTitle: true),
      body: Consumer2<HomeViewModel, PlaylistViewModel>(
        builder: (context, homeVM, playerVM, _) {
          if (homeVM.isLoading && !homeVM.hasHydratedLibrary) {
            return const AppStateView.loading(
              title: 'Carregando musicas',
              subtitle: 'Preparando sua biblioteca para reproduzir.',
            );
          }

          if (homeVM.lastSyncError != null && homeVM.musics.isEmpty) {
            return AppStateView.error(
              title: 'Nao foi possivel carregar a biblioteca',
              subtitle: homeVM.lastSyncError!,
              actionLabel: 'Tentar novamente',
              onAction: homeVM.manualRescan,
            );
          }

          final musics = homeVM.musics;
          if (musics.isEmpty) {
            return AppStateView.empty(
              icon: Icons.music_off_rounded,
              title: 'Nenhuma musica carregada',
              subtitle: homeVM.isScanning
                  ? 'Sincronizando biblioteca...'
                  : 'Adicione musicas no dispositivo e toque em reescanear.',
              actionLabel: 'Reescanear',
              onAction: homeVM.manualRescan,
            );
          }
          final filtered = _filterMusics(musics, playerVM);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'Buscar por musica, artista ou album',
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _quickFilter == _QuickFilter.all,
                      onSelected: (_) =>
                          setState(() => _quickFilter = _QuickFilter.all),
                    ),
                    ChoiceChip(
                      label: const Text('Favoritas'),
                      selected: _quickFilter == _QuickFilter.favorites,
                      onSelected: (_) =>
                          setState(() => _quickFilter = _QuickFilter.favorites),
                    ),
                    ChoiceChip(
                      label: const Text('Recentes'),
                      selected: _quickFilter == _QuickFilter.recent,
                      onSelected: (_) =>
                          setState(() => _quickFilter = _QuickFilter.recent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? AppStateView.empty(
                        icon: Icons.search_off_rounded,
                        title: 'Nenhum resultado encontrado',
                        subtitle: 'Nenhuma musica corresponde a "$_query".',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final music = filtered[index];
                          final isCurrent =
                              playerVM.currentMusic?.id == music.id;
                          final isFavorite = playerVM.favoriteMusics.any(
                            (m) => m.audioUrl == music.audioUrl,
                          );
                          final originalIndex = musics.indexOf(music);

                          return SwipeToRevealActions(
                            key: ValueKey('all-musics-${music.audioUrl}'),
                            height: 78,
                            isFavorite: isFavorite,
                            deleteDialogTitle: 'Remover da biblioteca',
                            deleteDialogMessage:
                                'Deseja remover "${music.title}" da biblioteca?\n\n'
                                'O arquivo fisico no dispositivo nao sera apagado.',
                            deleteConfirmLabel: 'Remover',
                            onToggleFavorite: () async {
                              await playerVM.toggleFavorite(music);
                            },
                            onDelete: () async {
                              await homeVM.removeMusicFromLibrary(music);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Musica movida para a lixeira.',
                                  ),
                                ),
                              );
                            },
                            child: ListTile(
                              onTap: () async {
                                HapticFeedback.selectionClick();
                                await playerVM.playMusic(musics, originalIndex);
                                if (!context.mounted) return;
                                Navigator.pushNamed(context, AppRoutes.player);
                              },
                              leading: ArtworkThumb(
                                artworkUrl: music.artworkUrl,
                                audioId: music.sourceId ?? music.id,
                              ),
                              title: Text(
                                music.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                music.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isCurrent
                                  ? Icon(
                                      Icons.equalizer_rounded,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              tileColor: theme
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 1),
                            ),
                          );
                        },
                      ),
              ),
              if (playerVM.currentMusic != null) const MiniPlayerView(),
            ],
          );
        },
      ),
    );
  }
}

enum _QuickFilter { all, favorites, recent }
