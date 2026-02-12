import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/data/models/search_result.dart';
import 'package:music_music/app/routes.dart';

import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/features/home/widgets/permission_denied_view.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/search_results_view.dart';
import 'package:music_music/shared/widgets/skeleton.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';

import 'package:music_music/core/theme/app_shadows.dart';
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
          return const _MusicListSkeleton();
        }

        // sua BUSCA ATIVA
        if (vm.currentQuery.isNotEmpty) {
          return SearchResultsView(
            results: vm.searchResults,
            query: vm.currentQuery,
            onTap: (result) async {
              final playlistVM = context.read<PlaylistViewModel>();

              switch (result.type) {
                case SearchType.music:
                  await playlistVM.playSingleMusic(result.music!);
                  if (!context.mounted) return;
                  Navigator.pushNamed(context, AppRoutes.player);
                  break;

                case SearchType.artist:
                  Navigator.pushNamed(
                    context,
                    AppRoutes.artistDetail,
                    arguments: ArtistDetailArgs(artistName: result.title),
                  );
                  break;

                case SearchType.album:
                  Navigator.pushNamed(
                    context,
                    AppRoutes.albumDetail,
                    arguments: AlbumDetailArgs(albumName: result.title),
                  );
                  break;
              }
            },
          );
        }

        // sua LISTA NORMAL
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
            final shadows =
                Theme.of(context).extension<AppShadows>()?.surface ?? [];

            ArtworkCache.preload(context, music.artworkUrl);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PressableTile(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final playlistVM = context.read<PlaylistViewModel>();
                  await playlistVM.playMusic(vm.visibleMusics, index);
                  if (!context.mounted) return;
                  Navigator.pushNamed(context, AppRoutes.player);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: shadows,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: ArtworkThumb(artworkUrl: music.artworkUrl),
                    title: Text(
                      music.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      music.album == null || music.album!.isEmpty
                          ? music.artist
                          : '${music.artist} Ã¡lb ${music.album}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatDuration(music.duration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
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
    return Selector<PlaylistViewModel, List<MusicEntity>>(
      selector: (_, vm) => vm.favoriteMusics,
      builder: (context, favorites, _) {

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
            final shadows =
                Theme.of(context).extension<AppShadows>()?.surface ?? [];

            ArtworkCache.preload(context, music.artworkUrl);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PressableTile(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await context.read<PlaylistViewModel>().playMusic(
                        favorites,
                        index,
                      );
                  if (!context.mounted) return;
                  Navigator.pushNamed(context, AppRoutes.player);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: shadows,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: ArtworkThumb(artworkUrl: music.artworkUrl),
                    title: Text(music.title),
                    subtitle: Text(music.artist),
                  ),
                ),
              ),
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
              return const _GridSkeleton();
            }

            final playlists = snapshot.data as List<Map<String, dynamic>>;

            if (playlists.isEmpty) {
              return _EmptyState(
                icon: Icons.queue_music,
                text: 'Nenhuma playlist criada',
                subtitle: 'Crie sua primeira playlist para organizar sua vibe.',
                actionLabel: 'Criar playlist',
                onAction: () {
                  Navigator.pushNamed(context, AppRoutes.playlists);
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
                final shadows =
                    Theme.of(context).extension<AppShadows>()?.elevated ?? [];

                return _PressableTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pushNamed(
                      context,
                      AppRoutes.playlistDetail,
                      arguments: PlaylistDetailArgs(
                        playlistId: p['id'],
                        playlistName: p['name'],
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: shadows,
                    ),
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
    final albumGroups =
        context.select<HomeViewModel, List<AlbumGroup>>((vm) => vm.albumGroups);

    if (albumGroups.isEmpty) {
      return const _GridSkeleton();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: albumGroups.length,
      itemBuilder: (context, index) {
        final group = albumGroups[index];
        final artwork = _getAlbumArtwork(group.musics);
        ArtworkCache.preload(context, artwork);

        return _PressableTile(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(
              context,
              AppRoutes.albumDetail,
              arguments: AlbumDetailArgs(
                albumName: group.album,
                artistName: group.artist,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ã°Å¸Å½Â¬ HERO AQUI
              Hero(
                tag: 'album_${group.album}__${group.artist}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ArtworkSquare(
                      artworkUrl: artwork,
                      borderRadius: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                group.album,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              Text(
                '${group.artist} ï¿½ ${group.musics.length} mÃºsicas',
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
    final artists = context.select<HomeViewModel,
        Map<String, List<MusicEntity>>>((vm) => vm.artistsGrouped);

    if (artists.isEmpty) {
      return const _ListSkeleton();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists.keys.elementAt(index);
        final artistMusics = artists[artist]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PressableTile(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pushNamed(
                context,
                AppRoutes.artistDetail,
                arguments: ArtistDetailArgs(artistName: artist),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    Theme.of(context).extension<AppShadows>()?.surface ?? [],
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableTile({
    required this.child,
    required this.onTap,
  });

  @override
  State<_PressableTile> createState() => _PressableTileState();
}

class _PressableTileState extends State<_PressableTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
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


class _MusicListSkeleton extends StatelessWidget {
  const _MusicListSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = theme.extension<AppShadows>()?.surface ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: shadows,
            ),
            child: const Row(
              children: [
                Skeleton(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: double.infinity, height: 14),
                      SizedBox(height: 8),
                      Skeleton(width: 140, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Skeleton(width: 36, height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = theme.extension<AppShadows>()?.elevated ?? [];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: shadows,
              ),
              child: const Skeleton(
                width: double.infinity,
                height: 140,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),
            const Skeleton(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            const Skeleton(width: 80, height: 10),
          ],
        );
      },
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = theme.extension<AppShadows>()?.surface ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: shadows,
            ),
            child: const Row(
              children: [
                Skeleton(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: double.infinity, height: 14),
                      SizedBox(height: 8),
                      Skeleton(width: 120, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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


