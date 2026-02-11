// lib/views/home/home_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_music/core/web_upload/web_drag_drop_area.dart';
import 'package:music_music/core/web_upload/web_music_uploader.dart';
import 'package:music_music/features/folders/view/folders_view.dart';
import 'package:music_music/features/genres/view/genres_view.dart';

import 'package:music_music/features/home/widgets/home_header.dart';
import 'package:music_music/features/player/view/sliding_player_panel.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:provider/provider.dart';
import 'package:music_music/app/routes.dart';

import 'package:music_music/features/home/widgets/home_tabs.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _currentIndex = 0;

  late HomeViewModel _homeVM;

  @override
  void initState() {
    super.initState();

    // pega o ViewModel uma Ãºnica vez
    _homeVM = context.read<HomeViewModel>();

    // escuta mudanÃ§as do ViewModel
    _homeVM.addListener(_onHomeChanged);
  }

  void _onHomeChanged() {
    if (_homeVM.showScanSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('suas Músicas carregadas com sucesso'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      _homeVM.consumeScanSuccess();
    }
  }

  @override
  void dispose() {
    _homeVM.removeListener(_onHomeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 420;

    return Scaffold(
      drawer: const _HomeDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Consumer<HomeViewModel>(
                  builder: (context, vm, _) {
                    return HomeHeader(
                      canPlay: vm.visibleMusics.isNotEmpty,
                      onPlayAll: () async {
                        final playlistVM =
                            context.read<PlaylistViewModel>();
                        final musics = vm.visibleMusics;

                        if (musics.isEmpty) return;

                        await playlistVM.playAllFromPlaylist(musics);
                        Navigator.pushNamed(context, AppRoutes.player);
                      },
                      onShuffleAll: () async {
                        final playlistVM =
                            context.read<PlaylistViewModel>();
                        final musics = vm.visibleMusics;

                        if (musics.isEmpty) return;

                        if (!playlistVM.isShuffled) {
                          await playlistVM.toggleShuffle();
                        }

                        await playlistVM.playAllFromPlaylist(musics);
                        Navigator.pushNamed(context, AppRoutes.player);
                      },
                    );
                  },
                ),

                // ðŸŒ UPLOAD WEB
                if (kIsWeb)
                  Selector<HomeViewModel, bool>(
                    selector: (_, vm) =>
                        !vm.isLoading && vm.musics.isEmpty,
                    builder: (context, showUpload, _) {
                      if (!showUpload) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: WebDragDropArea(
                          onFiles: (files) async {
                            final uploaded =
                                await WebMusicUploader.upload(files);

                            final vm = context.read<HomeViewModel>();

                            for (final music in uploaded) {
                              await vm.insertWebMusic(music);
                            }
                          },
                        ),
                      );
                    },
                  ),

                Expanded(
                  child: DefaultTabController(
                    length: 6,
                    initialIndex: _currentIndex,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 8 : 16,
                          ),
                          indicator: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          indicatorPadding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          labelColor: theme.colorScheme.onPrimary,
                          unselectedLabelColor: theme.colorScheme.onSurface,
                          labelStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle:
                              theme.textTheme.labelLarge,
                          tabs: const [
                            Tab(text: 'Músicas'),
                            Tab(text: 'Álbuns'),
                            Tab(text: 'Artistas'),
                            Tab(text: 'Pastas'),
                            Tab(text: 'Gêneros'),
                            Tab(text: 'Playlists'),
                          ],
                          onTap: (index) => setState(
                            () => _currentIndex = index,
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: const [
                              HomeMusicsTab(),
                              HomeAlbumsTab(),
                              HomeArtistsTab(),
                              FoldersView(),
                              GenresView(),
                              HomePlaylistsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ðŸŽµ MINI PLAYER
            Consumer2<PlaylistViewModel, HomeViewModel>(
              builder: (context, playerVM, homeVM, _) {
                if (playerVM.currentMusic == null) {
                  return const SizedBox.shrink();
                }

                return SlidingPlayerPanel(showGlow: homeVM.showMiniPlayerGlow);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Music Music',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            _DrawerItem(icon: Icons.favorite, label: 'Favoritas', onTap: () {}),
            _DrawerItem(
              icon: Icons.library_music,
              label: 'Músicas',
              onTap: () {},
            ),
            _DrawerItem(
              icon: Icons.queue_music,
              label: 'Playlists',
              onTap: () {},
            ),
            _DrawerItem(icon: Icons.album, label: 'Albuns', onTap: () {}),
            _DrawerItem(icon: Icons.person, label: 'Artistas', onTap: () {}),
            _DrawerItem(icon: Icons.folder, label: 'Pastas', onTap: () {}),

            const Spacer(),
            const Divider(),

            _DrawerItem(
              icon: Icons.settings,
              label: 'Temas',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.themes);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      onTap: onTap,
    );
  }
}
