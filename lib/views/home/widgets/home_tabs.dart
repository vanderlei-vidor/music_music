import 'package:flutter/material.dart';
import 'package:music_music/core/ui/TextSpan_highlight.dart';

import 'package:music_music/models/music_entity.dart';
import 'package:music_music/models/search_result.dart';
import 'package:music_music/views/album/album_detail_screen.dart';
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
                          ArtistDetailView(artistName: result.title),
                    ),
                  );
                  break;

                case SearchType.album:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AlbumDetailScreen(albumName: result.title),
                    ),
                  );
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
              leading: const CircleAvatar(child: Icon(Icons.music_note)),
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

  String? _getAlbumArtwork(List<MusicEntity> musics) {
    for (final m in musics) {
      if (m.artworkUrl != null && m.artworkUrl!.isNotEmpty) {
        return m.artworkUrl;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final musics = context.watch<HomeViewModel>().musics;

    final albums = <String, List<MusicEntity>>{};
    for (final m in musics) {
      albums.putIfAbsent(m.album ?? 'Desconhecido', () => []).add(m);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final albumName = albums.keys.elementAt(index);
        final albumMusics = albums[albumName]!;

        final artwork = _getAlbumArtwork(albumMusics);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlbumDetailScreen(albumName: albumName),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🎬 HERO AQUI
              Hero(
                tag: 'album_$albumName',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: artwork != null
                        ? Image.network(artwork, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade800,
                            child: const Icon(
                              Icons.album,
                              size: 64,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                albumName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              Text(
                '${albumMusics.length} músicas',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeArtistsTab extends StatelessWidget {
  const HomeArtistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final musics = context.watch<HomeViewModel>().musics;

    // agrupa por artista
    final Map<String, List<MusicEntity>> artists = {};
    for (final m in musics) {
      final name = m.artist.isNotEmpty ? m.artist : 'Desconhecido';
      artists.putIfAbsent(name, () => []).add(m);
    }

    if (artists.isEmpty) {
      return const _EmptyState(
        icon: Icons.person,
        text: 'Nenhum artista encontrado',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists.keys.elementAt(index);
        final artistMusics = artists[artist]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: Theme.of(context).colorScheme.surfaceVariant,
            leading: Hero(
              tag: 'artist_$artist',
              child: CircleAvatar(radius: 24, child: const Icon(Icons.person)),
            ),
            title: Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text('${artistMusics.length} músicas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistDetailView(artistName: artist),
                ),
              );
            },
          ),
        );
      },
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
