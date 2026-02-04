import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_music/models/music_entity.dart';
import 'package:music_music/models/search_result.dart';
import 'package:music_music/views/album/album_detail_screen.dart';
import 'package:music_music/views/artist/artist_detail_screen.dart';

import 'package:music_music/views/home/home_view_model.dart';
import 'package:music_music/views/home/widgets/permission_denied_view.dart';
import 'package:music_music/views/player/player_view.dart';
import 'package:music_music/views/playlist/playlist_detail_screen.dart';
import 'package:music_music/views/playlist/playlist_view_model.dart';
import 'package:music_music/views/playlist/playlists_screen.dart';
import 'package:music_music/widgets/search_results_view.dart';
import 'package:provider/provider.dart';

class HomeMusicsTab extends StatelessWidget {
  const HomeMusicsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        if (vm.permissionDenied) {
          return PermissionDeniedView(
            onRetry: () => vm.manualRescan(),
          );
        }

        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // ðŸ” BUSCA ATIVA
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

        // ðŸŽµ LISTA NORMAL
        if (vm.visibleMusics.isEmpty) {
          return _EmptyState(
            icon: Icons.library_music,
            text: 'Nenhuma mÃºsica encontrada',
            subtitle: kIsWeb
                ? 'Use a Ã¡rea de upload acima para adicionar suas mÃºsicas.'
                : 'Escaneie seu dispositivo para importar suas mÃºsicas.',
            actionLabel: kIsWeb ? null : 'Escanear agora',
            onAction: kIsWeb ? null : () => vm.manualRescan(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.visibleMusics.length,
          itemBuilder: (_, index) {
            final music = vm.visibleMusics[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceVariant,
                leading: _ArtworkThumb(artworkUrl: music.artworkUrl),
                title: Text(
                  music.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  music.album == null || music.album!.isEmpty
                      ? music.artist
                      : '${music.artist} â€¢ ${music.album}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatDuration(music.duration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () async {
                  final playlistVM = context.read<PlaylistViewModel>();

                  await playlistVM.playMusic(vm.visibleMusics, index);

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerView()),
                  );
                },
              ),
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
            text: 'Nenhuma mÃºsica favorita',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (_, index) {
            final music = favorites[index];

            return ListTile(
              leading: _ArtworkThumb(artworkUrl: music.artworkUrl),
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
              return _EmptyState(
                icon: Icons.queue_music,
                text: 'Nenhuma playlist criada',
                subtitle: 'Crie sua primeira playlist para organizar sua vibe.',
                actionLabel: 'Criar playlist',
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlaylistsScreen(),
                    ),
                  );
                },
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
                            '${p['musicCount']} mÃºsicas',
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
              // ðŸŽ¬ HERO AQUI
              Hero(
                tag: 'album_$albumName',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: artwork != null
                        ? Image.network(
                            artwork,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _ArtworkFallback();
                            },
                            errorBuilder: (_, __, ___) => _ArtworkFallback(),
                          )
                        : _ArtworkFallback(),
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
                '${albumMusics.length} mÃºsicas',
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
              child: CircleAvatar(
                radius: 24,
                child: Text(
                  artist.isNotEmpty ? artist[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            title: Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text('${artistMusics.length} mÃºsicas'),
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
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.text,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(text, style: theme.textTheme.bodyLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArtworkThumb extends StatelessWidget {
  final String? artworkUrl;

  const _ArtworkThumb({required this.artworkUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: artworkUrl != null && artworkUrl!.isNotEmpty
            ? Image.network(
                artworkUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ArtworkFallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _ArtworkFallback();
                },
              )
            : _ArtworkFallback(),
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.35),
            theme.colorScheme.secondary.withOpacity(0.35),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white70,
      ),
    );
  }
}

String _formatDuration(int? durationMs) {
  if (durationMs == null || durationMs <= 0) return '--:--';
  final totalSeconds = (durationMs / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
