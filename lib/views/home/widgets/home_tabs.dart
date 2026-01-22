import 'package:flutter/material.dart';
import 'package:music_music/core/ui/TextSpan_highlight.dart';

import 'package:music_music/models/music_entity.dart';
import 'package:music_music/models/search_result.dart';
import 'package:music_music/views/artist/artist_detail_screen.dart';
import 'package:music_music/views/home/home_view_model.dart';
import 'package:music_music/views/home/widgets/permission_denied_view.dart';
import 'package:music_music/views/player/player_view.dart';
import 'package:music_music/views/playlist/playlist_detail_screen.dart';
import 'package:music_music/views/playlist/playlist_view_model.dart';
import 'package:music_music/widgets/search_results_view.dart';
import 'package:provider/provider.dart';

class HomeMusicsTab extends StatelessWidget {
  const HomeMusicsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        if (vm.permissionDenied) {
          return const PermissionDeniedView();
        }

        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔍 BUSCA ATIVA
        if (vm.currentQuery.isNotEmpty) {
          return SearchResultsView(
            results: vm.searchResults,
            query: vm.currentQuery,
            onTap: (result) async {
              final playlistVM = context.read<PlaylistViewModel>();

              switch (result.type) {
                case SearchType.music:
                  await playlistVM.playSingleMusic(result.music!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerView()),
                  );
                  break;

                case SearchType.artist:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ArtistDetailScreen(artistName: result.title),
                    ),
                  );
                  break;

                case SearchType.album:
                  // próximo passo depois
                  break;
              }
            },
          );
        }

        // 🎵 LISTA NORMAL
        if (vm.visibleMusics.isEmpty) {
          return const _EmptyState(
            icon: Icons.library_music,
            text: 'Nenhuma música encontrada',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.visibleMusics.length,
          itemBuilder: (_, index) {
            final music = vm.visibleMusics[index];

            return ListTile(
              title: Text(music.title),
              subtitle: Text(music.artist),
              onTap: () async {
                final playlistVM = context.read<PlaylistViewModel>();

                await playlistVM.playMusic(vm.visibleMusics, index);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerView()),
                );
              },
            );
          },
        );
      },
    );
  }
}

class HomeFavoritesTab extends StatelessWidget {
  const HomeFavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistViewModel>(
      builder: (context, vm, _) {
        final favorites = vm.favoriteMusics;

        if (favorites.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_border,
            text: 'Nenhuma música favorita',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (_, index) {
            final music = favorites[index];

            return ListTile(
              leading: const Icon(Icons.favorite, color: Colors.redAccent),
              title: Text(music.title),
              subtitle: Text(music.artist),
              onTap: () async {
                await vm.playMusic(favorites, index);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerView()),
                );
              },
            );
          },
        );
      },
    );
  }
}

class HomePlaylistsTab extends StatelessWidget {
  const HomePlaylistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistViewModel>(
      builder: (context, vm, _) {
        return FutureBuilder(
          future: vm.getPlaylistsWithMusicCount(),
          builder: (_, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final playlists = snapshot.data as List<Map<String, dynamic>>;

            if (playlists.isEmpty) {
              return const _EmptyState(
                icon: Icons.queue_music,
                text: 'Nenhuma playlist criada',
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: playlists.length,
              itemBuilder: (_, index) {
                final p = playlists[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailScreen(
                          playlistId: p['id'],
                          playlistName: p['name'],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.queue_music, size: 36),
                          const SizedBox(height: 8),
                          Text(p['name'], textAlign: TextAlign.center),
                          Text(
                            '${p['musicCount']} músicas',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class HomeAlbumsTab extends StatelessWidget {
  const HomeAlbumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final musics = context.watch<HomeViewModel>().musics;

    final albums = <String, List<MusicEntity>>{};
    for (final m in musics) {
      albums.putIfAbsent(m.album ?? 'Desconhecido', () => []).add(m);
    }

    return ListView(
      children: albums.keys.map((album) {
        return ListTile(
          leading: const Icon(Icons.album),
          title: Text(album),
          subtitle: Text('${albums[album]!.length} músicas'),
        );
      }).toList(),
    );
  }
}

class HomeArtistsTab extends StatelessWidget {
  const HomeArtistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final musics = context.watch<HomeViewModel>().musics;

    final artists = <String, List<MusicEntity>>{};
    for (final m in musics) {
      artists.putIfAbsent(m.artist ?? 'Desconhecido', () => []).add(m);
    }

    return ListView(
      children: artists.keys.map((artist) {
        return ListTile(
          leading: const Icon(Icons.album),
          title: Text(artist),
          subtitle: Text('${artists[artist]!.length} músicas'),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
