import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/data/models/search_result.dart';
import 'package:music_music/app/routes.dart';

import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/features/home/widgets/permission_denied_view.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/search_results_view.dart';
import 'package:music_music/shared/widgets/skeleton.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';
import 'package:music_music/shared/widgets/swipe_to_reveal_actions.dart';
import 'package:music_music/shared/widgets/playlist_play_shuffle_button.dart';
import 'package:music_music/core/ui/responsive.dart';

import 'package:music_music/core/theme/app_shadows.dart';
import 'package:provider/provider.dart';

class HomeMusicsTab extends StatelessWidget {
  const HomeMusicsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeViewModel, PlaylistViewModel>(
      builder: (context, vm, playerVM, _) {
        if (vm.permissionDenied) {
          return PermissionDeniedView(onRetry: () => vm.manualRescan());
        }

        if (vm.isLoading) {
          return const _MusicListSkeleton();
        }

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

        if (vm.visibleMusics.isEmpty) {
          return _EmptyState(
            icon: Icons.library_music,
            text: 'Nenhuma musica encontrada',
            subtitle: kIsWeb
                ? 'Use a area de upload acima para adicionar suas musicas.'
                : 'Escaneie seu dispositivo para importar suas musicas.',
            actionLabel: kIsWeb ? null : 'Escanear agora',
            onAction: kIsWeb ? null : () => vm.manualRescan(),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
          children: [
            _HomeRailSection(
              title: 'Feito para voce',
              queue: vm.visibleMusics,
              items: vm.visibleMusics.take(18).toList(),
            ),
            const SizedBox(height: 20),
            _HomeRailSection(
              title: 'Reviva seus Favoritos',
              queue: playerVM.favoriteMusics,
              items: playerVM.favoriteMusics.take(18).toList(),
              emptyLabel: 'Marque musicas como favoritas para aparecer aqui.',
            ),
            const SizedBox(height: 20),
            _HomeRailSection(
              title: 'Mais tocadas',
              queue: playerVM.mostPlayed,
              items: playerVM.mostPlayed.take(18).toList(),
              emptyLabel: 'Suas mais tocadas vao aparecer aqui.',
            ),
            const SizedBox(height: 20),
            _HomeRailSection(
              title: 'Tocadas recentes',
              queue: playerVM.recentMusics,
              items: playerVM.recentMusics.take(18).toList(),
              emptyLabel: 'Suas reproducoes recentes vao aparecer aqui.',
            ),
          ],
        );
      },
    );
  }
}

class _HomeRailSection extends StatelessWidget {
  final String title;
  final List<MusicEntity> queue;
  final List<MusicEntity> items;
  final String? emptyLabel;

  const _HomeRailSection({
    required this.title,
    required this.queue,
    required this.items,
    this.emptyLabel,
  });

  void _openAllTracks(BuildContext context) {
    if (queue.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SectionTracksScreen(
          title: title,
          queue: List<MusicEntity>.from(queue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (emptyLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              emptyLabel!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _openAllTracks(context),
              child: const Text('Ver tudo'),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface.withValues(alpha: 0.92),
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.74,
                ),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final music = items[index];
                final queueIndex = queue.indexWhere((m) => m.id == music.id);

                return _StaggerReveal(
                  delayMs: 35 * index,
                  child: _MusicCircleCard(
                    music: music,
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final playlistVM = context.read<PlaylistViewModel>();
                      final safeIndex = queueIndex < 0 ? 0 : queueIndex;
                      await playlistVM.playMusic(queue, safeIndex);
                      if (!context.mounted) return;
                      Navigator.pushNamed(context, AppRoutes.player);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MusicCircleCard extends StatelessWidget {
  final MusicEntity music;
  final VoidCallback onTap;

  const _MusicCircleCard({required this.music, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ArtworkCache.preload(context, music.artworkUrl);

    return SizedBox(
      width: 92,
      child: _PressableTile(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: Builder(
                  builder: (context) {
                    final provider = ArtworkCache.provider(music.artworkUrl);
                    if (provider == null) return _fallbackCircle(theme);
                    return Image(
                      image: provider,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => _fallbackCircle(theme),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              music.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              music.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCircle(ThemeData theme) {
    final artworkId = music.sourceId ?? music.id;
    if (!kIsWeb && artworkId != null) {
      return QueryArtworkWidget(
        id: artworkId,
        type: ArtworkType.AUDIO,
        artworkFit: BoxFit.cover,
        nullArtworkWidget: _defaultCircleFallback(theme),
      );
    }
    return _defaultCircleFallback(theme);
  }

  Widget _defaultCircleFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.music_note_rounded, color: theme.colorScheme.primary),
    );
  }
}

class _StaggerReveal extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const _StaggerReveal({required this.child, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final y = (1 - value) * 14;
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, y), child: child),
        );
      },
    );
  }
}

class _SectionTracksScreen extends StatefulWidget {
  final String title;
  final List<MusicEntity> queue;

  const _SectionTracksScreen({required this.title, required this.queue});

  @override
  State<_SectionTracksScreen> createState() => _SectionTracksScreenState();
}

class _SectionTracksScreenState extends State<_SectionTracksScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<MusicEntity> _sectionQueue;
  final ScrollController _scrollController = ScrollController();
  bool _showSwipeHint = true;
  bool _playButtonVisualState = false;
  double _headerT = 0;
  bool _wasCompact = false;

  @override
  void initState() {
    super.initState();
    _sectionQueue = List<MusicEntity>.from(widget.queue);
    _scrollController.addListener(_onScroll);
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (_showSwipeHint) {
        setState(() => _showSwipeHint = false);
      }
    });
  }

  void _onScroll() {
    final t = (_scrollController.offset / 120).clamp(0.0, 1.0);
    final isCompact = t >= 0.65;
    if (isCompact && !_wasCompact) {
      HapticFeedback.lightImpact();
    }
    _wasCompact = isCompact;
    if ((t - _headerT).abs() < 0.02) return;
    setState(() => _headerT = t);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MusicEntity> _filteredTracks() {
    var list = List<MusicEntity>.from(_sectionQueue);
    final q = _searchController.text.trim().toLowerCase();

    if (q.isNotEmpty) {
      list = list.where((m) {
        return m.title.toLowerCase().contains(q) ||
            m.artist.toLowerCase().contains(q) ||
            (m.album ?? '').toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  Future<void> _openSearchDialog() async {
    final controller = TextEditingController(text: _searchController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Buscar nesta secao'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Titulo, artista ou album',
            ),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: const Text('Limpar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _searchController.text = result.trim();
    });
  }

  Future<void> _playAll(List<MusicEntity> tracks) async {
    if (tracks.isEmpty) return;
    setState(() => _playButtonVisualState = !_playButtonVisualState);
    final vm = context.read<PlaylistViewModel>();
    await vm.playAllFromPlaylist(tracks);
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.player);
  }

  Future<void> _shuffleAll(List<MusicEntity> tracks) async {
    if (tracks.isEmpty) return;
    final vm = context.read<PlaylistViewModel>();
    if (!vm.isShuffled) {
      await vm.toggleShuffle();
    }
    await vm.playAllFromPlaylist(tracks);
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.player);
  }

  Future<void> _toggleFavorite(MusicEntity music) async {
    if (_showSwipeHint) {
      setState(() => _showSwipeHint = false);
    }
    final vm = context.read<PlaylistViewModel>();
    final newValue = await vm.toggleFavorite(music);
    if (!mounted) return;

    setState(() {
      final index = _sectionQueue.indexWhere(
        (m) => m.audioUrl == music.audioUrl,
      );
      if (index != -1) {
        _sectionQueue[index] = _sectionQueue[index].copyWith(
          isFavorite: newValue,
        );
      }
    });
  }

  void _removeFromSection(MusicEntity music) {
    if (_showSwipeHint) {
      setState(() => _showSwipeHint = false);
    }
    setState(() {
      _sectionQueue.removeWhere((m) => m.audioUrl == music.audioUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracks = _filteredTracks();
    final currentId = context.select<PlaylistViewModel, int?>(
      (vm) => vm.currentMusic?.id,
    );

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            title: Text(widget.title),
            actions: [
              IgnorePointer(
                ignoring: _headerT < 0.65,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _headerT,
                  child: IconButton(
                    tooltip: 'Buscar',
                    onPressed: _openSearchDialog,
                    icon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IgnorePointer(
                  ignoring: tracks.isEmpty || _headerT < 0.65,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: tracks.isEmpty ? 0.3 : _headerT,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      offset: Offset(
                        0.12 * (1 - _headerT),
                        -0.08 * (1 - _headerT),
                      ),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        scale: 0.56 + (0.18 * _headerT),
                        alignment: Alignment.centerRight,
                        child: PlaylistPlayShuffleButton(
                          isPlaying: _playButtonVisualState,
                          isShuffled: context.select<PlaylistViewModel, bool>(
                            (vm) => vm.isShuffled,
                          ),
                          onPlayPause: () => _playAll(tracks),
                          onShuffle: () => _shuffleAll(tracks),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(16, 84, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: 0.98),
                      theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.82,
                      ),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_sectionQueue.length} faixas nesta secao',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.76,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: 1 - _headerT,
                      child: Transform.scale(
                        scale: 1 - (_headerT * 0.12),
                        alignment: Alignment.topLeft,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Buscar nesta secao...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _searchController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface
                                      .withValues(alpha: 0.95),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IgnorePointer(
                              ignoring: tracks.isEmpty,
                              child: Opacity(
                                opacity: tracks.isEmpty ? 0.45 : 1,
                                child: AnimatedSlide(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutBack,
                                  offset: Offset(
                                    0.04 * _headerT,
                                    -0.06 * _headerT,
                                  ),
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeOutBack,
                                    scale: 1.08 - (0.22 * _headerT),
                                    child: PlaylistPlayShuffleButton(
                                      isPlaying: _playButtonVisualState,
                                      isShuffled: context
                                          .select<PlaylistViewModel, bool>(
                                            (vm) => vm.isShuffled,
                                          ),
                                      onPlayPause: () => _playAll(tracks),
                                      onShuffle: () => _shuffleAll(tracks),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showSwipeHint)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swipe_left_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dica: arraste a musica para a esquerda para favoritar ou remover desta pagina.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _showSwipeHint = false),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (tracks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Nenhuma faixa encontrada.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList.separated(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final music = tracks[index];
                  final isPlaying = currentId != null && currentId == music.id;
                  ArtworkCache.preload(context, music.artworkUrl);

                  return SwipeToRevealActions(
                    key: ValueKey('section-${music.audioUrl}-$index'),
                    height: 78,
                    isFavorite: music.isFavorite,
                    onToggleFavorite: () => _toggleFavorite(music),
                    onDelete: () => _removeFromSection(music),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isPlaying
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.55,
                                )
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.06,
                                ),
                          width: isPlaying ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          final playlistVM = context.read<PlaylistViewModel>();
                          await playlistVM.playMusic(tracks, index);
                          if (!context.mounted) return;
                          Navigator.pushNamed(context, AppRoutes.player);
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Builder(
                            builder: (_) {
                              final provider = ArtworkCache.provider(
                                music.artworkUrl,
                              );
                              if (provider == null) {
                                final artworkId = music.sourceId ?? music.id;
                                if (!kIsWeb && artworkId != null) {
                                  return QueryArtworkWidget(
                                    id: artworkId,
                                    type: ArtworkType.AUDIO,
                                    artworkFit: BoxFit.cover,
                                    nullArtworkWidget: _fallbackSquare(theme),
                                  );
                                }
                                return _fallbackSquare(theme);
                              }
                              return Image(
                                image: provider,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) =>
                                    _fallbackSquare(theme),
                              );
                            },
                          ),
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
                        trailing: Icon(
                          isPlaying
                              ? Icons.equalizer_rounded
                              : Icons.play_arrow_rounded,
                          color: isPlaying ? theme.colorScheme.primary : null,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallbackSquare(ThemeData theme) {
    return Container(
      width: 46,
      height: 46,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.music_note_rounded, color: theme.colorScheme.primary),
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
            text: 'Nenhuma mÃƒÆ’Ã‚Âºsica favorita',
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: shadows,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: ArtworkThumb(
                      artworkUrl: music.artworkUrl,
                      audioId: music.sourceId ?? music.id,
                    ),
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
        final playlists = vm.playlistsWithMusicCount;

        if (vm.isLoadingPlaylistsWithCount && playlists.isEmpty) {
          return const _GridSkeleton();
        }

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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsive.value(
              context,
              compact: 2,
              medium: 3,
              expanded: 4,
            ),
            crossAxisSpacing: Responsive.value(
              context,
              compact: 12.0,
              medium: 14.0,
              expanded: 16.0,
            ),
            mainAxisSpacing: Responsive.value(
              context,
              compact: 14.0,
              medium: 16.0,
              expanded: 18.0,
            ),
            mainAxisExtent:
                Responsive.value(
                  context,
                  compact: 154.0,
                  medium: 164.0,
                  expanded: 172.0,
                ) +
                ((MediaQuery.textScalerOf(context).scale(1.0) - 1.0).clamp(
                      0.0,
                      0.6,
                    ) *
                    36),
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
                        '${p['musicCount']} mÃƒÆ’Ã‚Âºsicas',
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
  }
}

class HomeAlbumsTab extends StatefulWidget {
  const HomeAlbumsTab({super.key});

  @override
  State<HomeAlbumsTab> createState() => _HomeAlbumsTabState();
}

class _HomeAlbumsTabState extends State<HomeAlbumsTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _getAlbumArtwork(List<MusicEntity> musics) {
    for (final m in musics) {
      if (m.artworkUrl != null && m.artworkUrl!.isNotEmpty) {
        return m.artworkUrl;
      }
    }
    return null;
  }

  int? _getAlbumArtworkId(List<MusicEntity> musics) {
    for (final m in musics) {
      final id = m.sourceId ?? m.id;
      if (id != null) return id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final albumGroups = context.select<HomeViewModel, List<AlbumGroup>>(
      (vm) => vm.albumGroups,
    );

    if (albumGroups.isEmpty) {
      return const _GridSkeleton();
    }

    final columns = Responsive.columnsForGrid(context);
    final crossSpacing = Responsive.value(
      context,
      compact: 12.0,
      medium: 14.0,
      expanded: 16.0,
    );
    final mainSpacing = Responsive.value(
      context,
      compact: 14.0,
      medium: 16.0,
      expanded: 18.0,
    );
    final mainExtent = Responsive.value(
      context,
      compact: 228.0,
      medium: 236.0,
      expanded: 246.0,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final dynamicMainExtent =
        mainExtent + ((textScale - 1.0).clamp(0.0, 0.6) * 42);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        mainAxisExtent: dynamicMainExtent,
      ),
      itemCount: albumGroups.length,
      itemBuilder: (context, index) {
        final group = albumGroups[index];
        final artwork = _getAlbumArtwork(group.musics);
        final artworkId = _getAlbumArtworkId(group.musics);
        ArtworkCache.preload(context, artwork);

        return AnimatedBuilder(
          animation: _controller,
          child: _PressableTile(
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
                Expanded(
                  child: Hero(
                    tag: 'album_${group.album}__${group.artist}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ArtworkSquare(
                          artworkUrl: artwork,
                          audioId: artworkId,
                          borderRadius: 16,
                        ),
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
                  '${group.artist} • ${group.musics.length} músicas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          builder: (context, child) {
            final animation = CurvedAnimation(
              parent: _controller,
              curve: Interval(
                (index / albumGroups.length).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

class HomeArtistsTab extends StatelessWidget {
  const HomeArtistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final artists = context
        .select<HomeViewModel, Map<String, List<MusicEntity>>>(
          (vm) => vm.artistsGrouped,
        );

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
                subtitle: Text('${artistMusics.length} mÃƒÆ’Ã‚Âºsicas'),
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

  const _PressableTile({required this.child, required this.onTap});

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
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
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
    final columns = Responsive.value(
      context,
      compact: 2,
      medium: 3,
      expanded: 4,
    );
    final crossSpacing = Responsive.value(
      context,
      compact: 12.0,
      medium: 14.0,
      expanded: 16.0,
    );
    final mainSpacing = Responsive.value(
      context,
      compact: 14.0,
      medium: 16.0,
      expanded: 18.0,
    );
    final mainExtent = Responsive.value(
      context,
      compact: 228.0,
      medium: 236.0,
      expanded: 246.0,
    );

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        mainAxisExtent: mainExtent,
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
