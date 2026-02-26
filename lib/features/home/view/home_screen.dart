import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/app/app_info.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/core/preferences/featured_prefs.dart';
import 'package:music_music/core/preferences/podcast_preferences.dart';
import 'package:music_music/core/web_upload/web_drag_drop_area.dart';
import 'package:music_music/core/web_upload/web_music_uploader.dart';
import 'package:music_music/core/preferences/welcome_prefs.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/delegates/music_search_delegate.dart';
import 'package:music_music/features/folders/view/folders_view.dart';
import 'package:music_music/features/genres/view/genres_view.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/features/home/widgets/home_header.dart';
import 'package:music_music/features/home/widgets/home_tabs.dart';
import 'package:music_music/features/player/view/sliding_player_panel.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

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

class _HomeViewState extends State<_HomeView>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _bottomNavIndex = 0;
  String _userName = 'Usuario';
  String? _featuredStoredDate;
  List<String>? _featuredStoredUrls;
  int _featuredStoredIndex = 0;
  int _featuredDayIndex = 0;
  String _featuredPersistedSignature = '';

  late HomeViewModel _homeVM;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _homeVM = context.read<HomeViewModel>();
    _homeVM.addListener(_onHomeChanged);
    _initTabController(6);
    _loadUserName();
    _loadFeaturedSnapshot();
  }

  void _initTabController(int length, {int initialIndex = 0}) {
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: initialIndex.clamp(0, length - 1),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _currentIndex != _tabController.index) {
        setState(() => _currentIndex = _tabController.index);
      }
    });
  }

  void _syncTabControllerLength(int length) {
    if (_tabController.length == length) return;
    final targetIndex = _currentIndex.clamp(0, length - 1);
    _tabController.dispose();
    _initTabController(length, initialIndex: targetIndex);
    _currentIndex = targetIndex;
  }

  Future<void> _loadUserName() async {
    final savedName = await WelcomePrefs.getUserName();
    if (!mounted || savedName == null || savedName.isEmpty) return;
    setState(() => _userName = savedName);
  }

  Future<void> _loadFeaturedSnapshot() async {
    final snapshot = await FeaturedPrefs.load();
    if (!mounted) return;
    setState(() {
      _featuredStoredDate = snapshot?.date;
      _featuredStoredUrls = snapshot?.audioUrls;
      _featuredStoredIndex = snapshot?.featuredIndex ?? 0;
      _featuredDayIndex = _featuredStoredIndex;
    });
  }

  Future<void> _openProfileSheet() async {
    final controller = TextEditingController(text: _userName);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Seu perfil',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nome de exibicao',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  await WelcomePrefs.saveUserName(name);
                  if (!mounted || !sheetContext.mounted) return;
                  setState(() => _userName = name);
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Salvar nome'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, AppRoutes.themes);
                },
                child: const Text('Abrir temas'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onHomeChanged() {
    if (_homeVM.showScanSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Suas musicas foram carregadas com sucesso.'),
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
    _tabController.dispose();
    super.dispose();
  }

  MusicEntity? _featuredOfDay(List<MusicEntity> musics) {
    if (musics.isEmpty) return null;
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final day = now.difference(startOfYear).inDays;
    return musics[day % musics.length];
  }

  String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  List<MusicEntity> _mapStoredQueue(
    List<String>? urls,
    List<MusicEntity> musics,
  ) {
    if (urls == null || urls.isEmpty || musics.isEmpty) return const [];
    final byUrl = {for (final m in musics) m.audioUrl: m};
    final mapped = <MusicEntity>[];
    for (final url in urls) {
      final m = byUrl[url];
      if (m != null) mapped.add(m);
    }
    return mapped;
  }

  int _seededJitter(String key) {
    var hash = 7;
    for (final code in key.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash % 53;
  }

  List<MusicEntity> _generateFeaturedQueue(
    HomeViewModel homeVM,
    PlaylistViewModel playlistVM,
    String today,
  ) {
    final musics = homeVM.visibleMusics;
    if (musics.isEmpty) return const [];

    final favoriteSet = playlistVM.favoriteMusics
        .map((m) => m.audioUrl)
        .toSet();
    final mostPlayedRank = <String, int>{};
    for (var i = 0; i < playlistVM.mostPlayed.length; i++) {
      mostPlayedRank[playlistVM.mostPlayed[i].audioUrl] = i;
    }
    final recentRank = <String, int>{};
    for (var i = 0; i < playlistVM.recentMusics.length; i++) {
      recentRank[playlistVM.recentMusics[i].audioUrl] = i;
    }

    final now = DateTime.now();
    final scored = musics.map((music) {
      var score = 0.0;

      if (favoriteSet.contains(music.audioUrl)) score += 220;

      final mostIdx = mostPlayedRank[music.audioUrl];
      if (mostIdx != null) score += (130 - mostIdx).clamp(35, 130);

      final recentIdx = recentRank[music.audioUrl];
      if (recentIdx != null) {
        score += (95 - recentIdx).clamp(20, 95);
      } else {
        score += 18;
      }

      final playCountWeight = (music.playCount * 4).clamp(0, 120);
      score += playCountWeight.toDouble();

      if (music.lastPlayedAt != null) {
        final playedAt = DateTime.fromMillisecondsSinceEpoch(
          music.lastPlayedAt!,
        );
        final days = now.difference(playedAt).inDays.clamp(0, 45);
        score += days * 1.5;
      } else {
        score += 26;
      }

      score += _seededJitter('${music.audioUrl}|$today');
      return (music: music, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(24).map((e) => e.music).toList();
  }

  List<MusicEntity> _featuredQueueFor(
    HomeViewModel homeVM,
    PlaylistViewModel playlistVM,
  ) {
    final today = _todayKey();
    final musics = homeVM.visibleMusics;

    final stored = _featuredStoredDate == today
        ? _mapStoredQueue(_featuredStoredUrls, musics)
        : const <MusicEntity>[];

    final queue = stored.isNotEmpty
        ? stored
        : _generateFeaturedQueue(homeVM, playlistVM, today);

    if (queue.isEmpty) return const [];

    final signature = '$today|${queue.first.audioUrl}|${queue.length}';
    if (_featuredPersistedSignature != signature) {
      _featuredPersistedSignature = signature;
      final index = _featuredStoredDate == today
          ? _featuredDayIndex.clamp(0, queue.length - 1)
          : 0;
      FeaturedPrefs.save(
        date: today,
        audioUrls: queue.map((m) => m.audioUrl).toList(),
        featuredIndex: index,
      );
    }

    return queue;
  }

  Future<void> _cycleFeatured(
    List<MusicEntity> queue,
    PlaylistViewModel playlistVM,
  ) async {
    if (queue.isEmpty) return;
    final today = _todayKey();
    final current = _featuredStoredDate == today
        ? _featuredDayIndex.clamp(0, queue.length - 1)
        : 0;
    final next = (current + 1) % queue.length;

    setState(() {
      _featuredStoredDate = today;
      _featuredDayIndex = next;
      _featuredStoredIndex = next;
      _featuredStoredUrls = queue.map((m) => m.audioUrl).toList();
    });

    await FeaturedPrefs.save(
      date: today,
      audioUrls: queue.map((m) => m.audioUrl).toList(),
      featuredIndex: next,
    );

    // Sincroniza o destaque visual com o tocador/mini player.
    await playlistVM.playMusic(queue, next);
  }

  Future<void> _openSearch() async {
    final result = await showSearch<String>(
      context: context,
      delegate: MusicSearchDelegate(_homeVM.musics),
    );

    if (!mounted || result == null || result.isEmpty) return;

    final selectedId = int.tryParse(result);
    if (selectedId == null) return;

    final index = _homeVM.musics.indexWhere((music) => music.id == selectedId);
    if (index < 0) return;

    final playlistVM = context.read<PlaylistViewModel>();
    await playlistVM.playMusic(_homeVM.musics, index);
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.player);
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      _openSearch();
      return;
    }

    if (_bottomNavIndex != index) {
      setState(() => _bottomNavIndex = index);
    }

    if (index == 0 && _tabController.index != 0) {
      _tabController.animateTo(0);
    }
  }

  void _openHomeTab(int index) {
    Navigator.pop(context);
    if (_bottomNavIndex != 0) {
      setState(() => _bottomNavIndex = 0);
    }
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final podcastsEnabled = context.watch<PodcastPreferences>().enabled;
    final tabCount = podcastsEnabled ? 7 : 6;
    _syncTabControllerLength(tabCount);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 420;

    return Scaffold(
      drawer: _HomeDrawer(onOpenTab: _openHomeTab),
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 16 : 28,
          0,
          isCompact ? 16 : 28,
          isCompact ? 6 : 8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: NavigationBar(
            height: isCompact ? 60 : 64,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            selectedIndex: _bottomNavIndex,
            onDestinationSelected: _onBottomNavTap,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                selectedIcon: Icon(Icons.search_rounded),
                label: 'Buscar',
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Consumer2<HomeViewModel, PlaylistViewModel>(
                  builder: (context, vm, playlistVM, _) {
                    final featuredQueue = _featuredQueueFor(vm, playlistVM);
                    final today = _todayKey();
                    final featuredIndex =
                        (featuredQueue.isNotEmpty &&
                            _featuredStoredDate == today)
                        ? _featuredDayIndex.clamp(0, featuredQueue.length - 1)
                        : 0;
                    final featured = featuredQueue.isNotEmpty
                        ? featuredQueue[featuredIndex]
                        : _featuredOfDay(vm.visibleMusics);

                    return HomeHeader(
                      canPlay: vm.visibleMusics.isNotEmpty,
                      userName: _userName,
                      featuredTitle: featured?.title,
                      featuredSubtitle: featured == null
                          ? null
                          : '${featured.artist}${(featured.album ?? '').isNotEmpty ? ' - ${featured.album}' : ''}',
                      featuredArtwork: featured?.artworkUrl,
                      featuredId: featured?.sourceId ?? featured?.id,
                      onAvatarTap: () {
                        _openProfileSheet();
                      },
                      onOpenSettings: () {
                        _openProfileSheet();
                      },
                      onNotificationTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sem novas notificacoes no momento.'),
                          ),
                        );
                      },
                      onPlayAll: () async {
                        final playlistVM = context.read<PlaylistViewModel>();
                        final musics = featuredQueue.isNotEmpty
                            ? featuredQueue
                            : vm.visibleMusics;

                        if (musics.isEmpty) return;

                        await playlistVM.playAllFromPlaylist(musics);
                        if (!context.mounted) return;
                        Navigator.pushNamed(context, AppRoutes.player);
                      },
                      onShuffleAll: () async {
                        final playlistVM = context.read<PlaylistViewModel>();
                        final musics = featuredQueue.isNotEmpty
                            ? featuredQueue
                            : vm.visibleMusics;

                        if (musics.isEmpty) return;

                        if (!playlistVM.isShuffled) {
                          await playlistVM.toggleShuffle();
                        }

                        await playlistVM.playAllFromPlaylist(musics);
                        if (!context.mounted) return;
                        Navigator.pushNamed(context, AppRoutes.player);
                      },
                      onCycleFeatured: featuredQueue.isNotEmpty
                          ? () => _cycleFeatured(featuredQueue, playlistVM)
                          : null,
                    );
                  },
                ),
                if (kIsWeb)
                  Selector<HomeViewModel, bool>(
                    selector: (_, vm) => !vm.isLoading && vm.musics.isEmpty,
                    builder: (context, showUpload, _) {
                      if (!showUpload) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: WebDragDropArea(
                          onFiles: (files) async {
                            final uploaded = await WebMusicUploader.upload(
                              files,
                            );
                            if (!context.mounted) return;

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
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 6 : 12,
                        ),
                        labelPadding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 10 : 12,
                        ),
                        dividerHeight: 0,
                        indicator: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        indicatorPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        labelColor: theme.colorScheme.onPrimary,
                        unselectedLabelColor: theme.colorScheme.onSurface,
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: isCompact ? 12 : null,
                        ),
                        unselectedLabelStyle: theme.textTheme.labelLarge
                            ?.copyWith(fontSize: isCompact ? 12 : null),
                        tabs: const [
                          Tab(height: 34, text: 'Musicas'),
                          Tab(height: 34, text: 'Albuns'),
                          Tab(height: 34, text: 'Artistas'),
                          Tab(height: 34, text: 'Pastas'),
                          Tab(height: 34, text: 'Generos'),
                          Tab(height: 34, text: 'Playlists'),
                        ] +
                            (podcastsEnabled
                                ? const [Tab(height: 34, text: 'Podcasts')]
                                : const []),
                        onTap: (index) => setState(() => _currentIndex = index),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            HomeMusicsTab(),
                            HomeAlbumsTab(),
                            HomeArtistsTab(),
                            FoldersView(),
                            GenresView(),
                            HomePlaylistsTab(),
                          ] +
                              (podcastsEnabled
                                  ? const [HomePodcastsTab()]
                                  : const []),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
  final ValueChanged<int> onOpenTab;

  const _HomeDrawer({required this.onOpenTab});

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
                    AppInfo.appName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _DrawerItem(
              icon: Icons.favorite,
              label: 'Favoritas',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.favorites);
              },
            ),
            _DrawerItem(
              icon: Icons.library_music,
              label: 'Musicas',
              onTap: () => onOpenTab(0),
            ),
            _DrawerItem(
              icon: Icons.album,
              label: 'Albuns',
              onTap: () => onOpenTab(1),
            ),
            _DrawerItem(
              icon: Icons.person,
              label: 'Artistas',
              onTap: () => onOpenTab(2),
            ),
            _DrawerItem(
              icon: Icons.folder,
              label: 'Pastas',
              onTap: () => onOpenTab(3),
            ),
            _DrawerItem(
              icon: Icons.graphic_eq,
              label: 'Generos',
              onTap: () => onOpenTab(4),
            ),
            _DrawerItem(
              icon: Icons.queue_music,
              label: 'Playlists',
              onTap: () => onOpenTab(5),
            ),
            if (context.watch<PodcastPreferences>().enabled)
              _DrawerItem(
                icon: Icons.podcasts_rounded,
                label: 'Podcasts',
                onTap: () => onOpenTab(6),
              ),
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
