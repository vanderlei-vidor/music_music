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
import 'package:music_music/features/player/view/equalizer_sheet.dart';
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

class _HomeViewState extends State<_HomeView> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  String _userName = 'Usuario';
  String? _featuredStoredDate;
  List<String>? _featuredStoredUrls;
  int _featuredStoredIndex = 0;
  int _featuredDayIndex = 0;
  String _featuredPersistedSignature = '';
  String? _lastPlaybackIssueSignature;
  DateTime? _lastPlaybackSnackAt;
  static const Duration _playbackSnackCooldown = Duration(seconds: 7);

  late HomeViewModel _homeVM;
  late PlaylistViewModel _playlistVM;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _homeVM = context.read<HomeViewModel>();
    _homeVM.addListener(_onHomeChanged);
    _playlistVM = context.read<PlaylistViewModel>();
    _playlistVM.addListener(_onPlaybackIssuesChanged);
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
          content: Text(_homeVM.lastSyncSummary),
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

  void _onPlaybackIssuesChanged() {
    final issues = _playlistVM.playbackIssues;
    if (issues.isEmpty || !mounted) return;

    final latest = issues.first;
    final signature =
        '${latest.when.microsecondsSinceEpoch}|${latest.stage}|${latest.audioUrl ?? ''}|${latest.message}';
    if (_lastPlaybackIssueSignature == signature) return;
    final now = DateTime.now();
    if (_lastPlaybackSnackAt != null &&
        now.difference(_lastPlaybackSnackAt!) < _playbackSnackCooldown) {
      return;
    }
    _lastPlaybackIssueSignature = signature;
    _lastPlaybackSnackAt = now;

    final theme = Theme.of(context);
    final title = _issueTitle(latest);
    final subtitle = latest.title?.trim().isNotEmpty == true
        ? latest.title!
        : 'Nao foi possivel tocar o audio selecionado.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Detalhes',
            onPressed: _openPlaybackIssuesTab,
          ),
        ),
      );
  }

  String _issueTitle(PlaybackIssue issue) {
    switch (issue.stage) {
      case 'set_audio_source':
        return 'Falha ao preparar a faixa';
      case 'resume_after_set_source':
        return 'Falha ao retomar reproducao';
      case 'play_music':
        return 'Falha ao iniciar reproducao';
      default:
        return 'Falha de reproducao detectada';
    }
  }

  @override
  void dispose() {
    _homeVM.removeListener(_onHomeChanged);
    _playlistVM.removeListener(_onPlaybackIssuesChanged);
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

  void _openPlaybackIssuesTab() {
    if (_tabController.index != 5) {
      _tabController.animateTo(5);
    }
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
      key: _scaffoldKey,
      drawer: const _HomeDrawer(),
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: isCompact ? 56 : 72,
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      onOpenDrawer: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      onOpenSettings: () {
                        _openProfileSheet();
                      },
                      onSearchTap: () {
                        _openSearch();
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
                Selector<HomeViewModel, bool>(
                  selector: (_, vm) => vm.isScanning && vm.musics.isNotEmpty,
                  builder: (context, isSyncing, _) {
                    if (!isSyncing) return const SizedBox.shrink();
                    final theme = Theme.of(context);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Atualizando biblioteca em segundo plano...',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        tabs:
                            const [
                              Tab(height: 34, text: 'Inicio'),
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
                          children:
                              const [
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
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
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
            const _DrawerSectionHeader(label: 'Biblioteca'),
            _DrawerItem(
              icon: Icons.favorite,
              label: 'Favoritas',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.favorites);
              },
            ),
            _DrawerItem(
              icon: Icons.sync_rounded,
              label: 'Reescanear biblioteca',
              onTap: () {
                Navigator.pop(context);
                context.read<HomeViewModel>().manualRescan();
              },
            ),
            _DrawerItem(
              icon: Icons.delete_sweep_outlined,
              label: 'Lixeira',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.trash);
              },
            ),
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
              _DrawerItem(
                icon: Icons.wifi_tethering_rounded,
                label: 'Importar no iPhone',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.iosImport).then((_) {
                    if (!context.mounted) return;
                    context.read<HomeViewModel>().manualRescan();
                  });
                },
              ),
            const Divider(height: 28),
            const _DrawerSectionHeader(label: 'Audio'),
            _DrawerItem(
              icon: Icons.graphic_eq_rounded,
              label: 'Equalizador',
              onTap: () {
                Navigator.pop(context);
                Future<void>.delayed(Duration.zero, () {
                  if (!context.mounted) return;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) => const EqualizerSheet(),
                  );
                });
              },
            ),
            _DrawerSwitchItem(
              icon: Icons.podcasts_rounded,
              label: 'Podcasts',
              value: context.watch<PodcastPreferences>().enabled,
              onChanged: (value) => context.read<PodcastPreferences>().setEnabled(value),
            ),
            _DrawerItem(
              icon: Icons.bedtime_rounded,
              label: 'Sleep timer',
              onTap: () {
                Navigator.pop(context);
                Future<void>.delayed(Duration.zero, () {
                  if (!context.mounted) return;
                  _openSleepTimerSheet(context);
                });
              },
            ),
            const Divider(height: 28),
            const _DrawerSectionHeader(label: 'Atividade'),
            _DrawerItem(
              icon: Icons.history_rounded,
              label: 'Tocadas recentes',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.recent);
              },
            ),
            _DrawerItem(
              icon: Icons.local_fire_department_rounded,
              label: 'Mais tocadas',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.mostPlayed);
              },
            ),
            const Divider(),
            const _DrawerSectionHeader(label: 'App'),
            _DrawerItem(
              icon: Icons.settings,
              label: 'Temas',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.themes);
              },
            ),
            _DrawerItem(
              icon: Icons.info_outline_rounded,
              label: 'Sobre',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.about);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSleepTimerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _DrawerSleepTimerSheet(),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  final String label;

  const _DrawerSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
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

class _DrawerSwitchItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DrawerSwitchItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _DrawerSleepTimerSheet extends StatefulWidget {
  const _DrawerSleepTimerSheet();

  @override
  State<_DrawerSleepTimerSheet> createState() => _DrawerSleepTimerSheetState();
}

class _DrawerSleepTimerSheetState extends State<_DrawerSleepTimerSheet> {
  final TextEditingController _minutesController = TextEditingController();

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _setMinutes(PlaylistViewModel vm, int minutes) {
    if (minutes <= 0) return;
    vm.setSleepTimer(Duration(minutes: minutes));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presets = [5, 10, 15, 30, 60];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Consumer<PlaylistViewModel>(
        builder: (_, vm, __) {
          final isActive = vm.hasSleepTimer;
          final activeMinutes = vm.sleepDuration?.inMinutes;
          final remaining = vm.sleepRemaining;
          final mode = vm.sleepMode;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Text(
                'Sleep Timer',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isActive
                    ? (mode == SleepTimerMode.duration
                        ? 'Ativo por $activeMinutes min'
                        : mode == SleepTimerMode.endOfSong
                            ? 'Ativo ate o fim da musica'
                            : mode == SleepTimerMode.endOfPlaylist
                                ? 'Ativo ate o fim da playlist'
                                : 'Ativo')
                    : 'Escolha quando parar a reproducao',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (remaining != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Restante: ${_formatDuration(remaining)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((m) {
                  final selected = activeMinutes == m && isActive;
                  return ChoiceChip(
                    label: Text('$m min'),
                    selected: selected,
                    onSelected: (_) => _setMinutes(vm, m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Fim da musica'),
                    selected: vm.sleepMode == SleepTimerMode.endOfSong,
                    onSelected: (_) {
                      vm.setSleepTimerEndOfSong();
                      Navigator.of(context).pop();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Fim da playlist'),
                    selected: vm.sleepMode == SleepTimerMode.endOfPlaylist,
                    onSelected: (_) {
                      vm.setSleepTimerEndOfPlaylist();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _minutesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Digite o numero de minutos',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onSubmitted: (value) {
                  final minutes = int.tryParse(value.trim());
                  if (minutes != null) _setMinutes(vm, minutes);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final minutes =
                            int.tryParse(_minutesController.text.trim());
                        if (minutes != null) _setMinutes(vm, minutes);
                      },
                      child: const Text('Ativar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isActive)
                    TextButton(
                      onPressed: () {
                        vm.cancelSleepTimer();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
