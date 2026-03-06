// lib/views/playlist/playlists_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_music/delegates/music_search_delegate.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:provider/provider.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/app_state_view.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  late Future<List<Map<String, dynamic>>> _playlistsFuture;
  String _query = '';
  _PlaylistSort _sort = _PlaylistSort.az;

  @override
  void initState() {
    super.initState();
    final vm = context.read<PlaylistViewModel>();
    _playlistsFuture = vm.getPlaylistsWithMusicCount();
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Criar Nova Playlist',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nome da Playlist',
            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                viewModel.createPlaylist(name);
                setState(() {
                  _playlistsFuture = viewModel.getPlaylistsWithMusicCount();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1400),
                      content: Text('Playlist "$name" criada'),
                    ),
                  );
              }
            },
            child: Text(
              'Criar',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    PlaylistViewModel viewModel,
    int playlistId,
    String playlistName,
  ) async {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja apagar a playlist "$playlistName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deletePlaylist(playlistId);
              setState(() {
                _playlistsFuture = viewModel.getPlaylistsWithMusicCount();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 1400),
                    content: Text('Playlist "$playlistName" excluida'),
                  ),
                );
            },
            child: Text(
              'Sim',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.read<PlaylistViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Playlists'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              HapticFeedback.selectionClick();
              _showCreatePlaylistDialog(context, viewModel);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              HapticFeedback.selectionClick();
              showSearch(
                context: context,
                delegate: MusicSearchDelegate(viewModel.libraryMusics),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppStateView.loading(
              title: 'Carregando playlists',
              subtitle: 'Buscando suas playlists salvas.',
            );
          }

          if (snapshot.hasError) {
            return AppStateView.error(
              title: 'Nao foi possivel carregar playlists',
              subtitle: snapshot.error.toString(),
              actionLabel: 'Tentar novamente',
              onAction: () {
                setState(() {
                  _playlistsFuture = viewModel.getPlaylistsWithMusicCount();
                });
              },
            );
          }

          final playlists = snapshot.data ?? [];
          final filtered = playlists.where((p) {
            final name = (p['name']?.toString() ?? '').toLowerCase();
            return name.contains(_query.trim().toLowerCase());
          }).toList();
          filtered.sort((a, b) {
            switch (_sort) {
              case _PlaylistSort.az:
                return (a['name']?.toString() ?? '')
                    .toLowerCase()
                    .compareTo((b['name']?.toString() ?? '').toLowerCase());
              case _PlaylistSort.mostSongs:
                return (b['musicCount'] as int).compareTo(a['musicCount'] as int);
            }
          });

          if (playlists.isEmpty) {
            return const AppStateView.empty(
              icon: Icons.queue_music_rounded,
              title: 'Nenhuma playlist criada',
              subtitle: 'Toque em + para criar sua primeira playlist.',
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar playlist (${filtered.length})',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('A-Z'),
                      selected: _sort == _PlaylistSort.az,
                      onSelected: (_) => setState(() => _sort = _PlaylistSort.az),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Mais musicas'),
                      selected: _sort == _PlaylistSort.mostSongs,
                      onSelected: (_) =>
                          setState(() => _sort = _PlaylistSort.mostSongs),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const AppStateView.empty(
                        icon: Icons.search_off_rounded,
                        title: 'Nenhuma playlist encontrada',
                        subtitle: 'Tente outro termo de busca.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final playlist = filtered[index];
                          final id = playlist['id'] as int;
                          final name = playlist['name'] as String;
                          final count = playlist['musicCount'] as int;
                          final shadows =
                              Theme.of(context).extension<AppShadows>()?.elevated ?? [];

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 260 + (index * 24)),
                            curve: Curves.easeOutCubic,
                            builder: (_, t, child) {
                              return Opacity(
                                opacity: t,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - t) * 14),
                                  child: child,
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'playlist_$id',
                              flightShuttleBuilder:
                                  (context, animation, direction, from, to) {
                                return Material(
                                  color: Colors.transparent,
                                  child: to.widget,
                                );
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: _PressableTile(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.playlistDetail,
                                      arguments: PlaylistDetailArgs(
                                        playlistId: id,
                                        playlistName: name,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: shadows,
                                    ),
                                    child: ListTile(
                                      leading: const Icon(Icons.queue_music),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '$count ${count == 1 ? 'musica' : 'musicas'}',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          _showDeleteConfirmationDialog(
                                            context,
                                            viewModel,
                                            id,
                                            name,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _PlaylistSort { az, mostSongs }

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

