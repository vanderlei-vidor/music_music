import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import 'package:music_music/app/app_info.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/shared/widgets/animated_favorite_icon.dart';
import 'package:music_music/shared/widgets/audio_wave.dart';
import 'package:music_music/shared/widgets/play_pause_button.dart';
import 'package:music_music/shared/widgets/progress_slider.dart';
import 'package:music_music/shared/widgets/animated_shuffle_button.dart';
import 'package:music_music/shared/widgets/repeat_button.dart';
import 'package:music_music/shared/widgets/speed_button.dart';
import 'package:music_music/shared/widgets/vertical_volume_slider.dart';
import 'package:music_music/shared/widgets/volume_equalizer.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';

import 'package:music_music/app/routes.dart';

class PlayerView extends StatefulWidget {
  const PlayerView({super.key});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  bool _showVolumeSlider = false;
  Timer? _volumeTimer;

  void _toggleVolume() {
    setState(() => _showVolumeSlider = true);

    _volumeTimer?.cancel();
    _volumeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showVolumeSlider = false);
    });
  }

  @override
  void dispose() {
    _volumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.read<PlaylistViewModel>();
    final ui = context.select<PlaylistViewModel, _PlayerScreenState>(
      (state) => _PlayerScreenState(
        music: state.currentMusic,
        isPlaying: state.isPlaying,
        volume: state.player.volume,
      ),
    );
    final music = ui.music;

    if (music == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context, music),
      body: Stack(
        children: [
          /// BACKGROUND PREMIUM
          Positioned.fill(child: _BackgroundArtwork(music: music)),

          /// CONTEUDO
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                /// CAPA
                Hero(
                  tag: music.audioUrl,
                  child: _ArtworkCover(music: music),
                ),

                const SizedBox(height: _PlayerLayout.spaceL),

                /// TITULO
                Text(
                  music.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: _PlayerLayout.spaceXs),

                Text(
                  music.artist,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: _PlayerLayout.spaceXl),

                /// WAVE + SLIDER
                AudioWave(
                  isPlaying: ui.isPlaying,
                  color: theme.colorScheme.primary,
                ),

                const SizedBox(height: _PlayerLayout.spaceSm),

                StreamBuilder<Duration>(
                  stream: vm.positionStream,
                  builder: (_, posSnap) {
                    final position = posSnap.data ?? Duration.zero;

                    final duration = Duration(
                      milliseconds: music.duration ?? 0,
                    );

                    return ProgressSlider(
                      position: position,
                      duration: duration,
                      onSeek: vm.seek,
                    );
                  },
                ),

                const SizedBox(height: _PlayerLayout.spaceXl),

                /// CONTROLES (AAA)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PressableScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        vm.previousMusic();
                      },
                      child: const Icon(
                        Icons.skip_previous,
                        size: _PlayerLayout.transportIconSize,
                      ),
                    ),
                    const SizedBox(width: _PlayerLayout.spaceXs),
                    _PressableScale(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        vm.playPause();
                      },
                      scale: 0.97,
                      child: IgnorePointer(
                        child: PlayPauseButton(
                          isPlaying: ui.isPlaying,
                          size: _PlayerLayout.playButtonSize,
                          color: theme.colorScheme.primary,
                          onTap: () {},
                        ),
                      ),
                    ),
                    const SizedBox(width: _PlayerLayout.spaceXs),
                    _PressableScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        vm.nextMusic();
                      },
                      child: const Icon(
                        Icons.skip_next,
                        size: _PlayerLayout.transportIconSize,
                      ),
                    ),
                  ],
                ),

                const Spacer(),
              ],
            ),
          ),

          /// VOLUME
          VolumeEqualizer(volume: ui.volume),

          if (_showVolumeSlider)
            Positioned(
              right: _PlayerLayout.spaceLg,
              bottom: _PlayerLayout.volumeSliderBottomOffset,
              child: VerticalVolumeSlider(
                volume: ui.volume,
                onChanged: vm.setVolume,
              ),
            ),
        ],
      ),
    );
  }

  // ===================== APP BAR =====================

  PreferredSizeWidget _buildAppBar(BuildContext context, MusicEntity music) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        AnimatedFavoriteIcon(
          isFavorite: music.isFavorite,
          activeColor: Colors.redAccent,
          onTap: () => context.read<PlaylistViewModel>().toggleFavorite(music),
        ),
        IconButton(
          icon: const Icon(Icons.playlist_play),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.playlists),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          onPressed: () {
            HapticFeedback.selectionClick();
            _openSideSheet(context);
          },
        ),
        IconButton(icon: const Icon(Icons.volume_up), onPressed: _toggleVolume),
      ],
    );
  }

  // ===================== DRAWER =====================

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.music_note, size: 42, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  AppInfo.appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          _drawerItem(
            context,
            Icons.history,
            'Tocadas recentemente',
            AppRoutes.recent,
          ),

          _drawerItem(
            context,
            Icons.favorite,
            'Favoritas',
            AppRoutes.favorites,
          ),

          const Divider(),

          _drawerItem(
            context,
            Icons.playlist_play,
            'Playlists',
            AppRoutes.playlists,
          ),

          _drawerItem(
            context,
            Icons.trending_up,
            'Mais tocadas',
            AppRoutes.mostPlayed,
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  // ===================== SPEED =====================

  void _openSpeed(BuildContext context, PlaylistViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SpeedSheet(
        currentSpeed: vm.currentSpeed,
        onChanged: vm.setPlaybackSpeed,
      ),
    );
  }

  void _openSideSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Fechar',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox.expand(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _PlayerSideSheet(
                  child: _PlayerControlsSheet(
                    onOpenSpeed: () {
                      final vm = context.read<PlaylistViewModel>();
                      Navigator.of(context).pop();
                      _openSpeed(context, vm);
                    },
                    onOpenTimer: () {
                      final vm = context.read<PlaylistViewModel>();
                      Navigator.of(context).pop();
                      _openTimerSheet(context, vm);
                    },
                    onOpenQueue: () {
                      Navigator.of(context).pop();
                      _openQueueSheet(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  void _openTimerSheet(BuildContext context, PlaylistViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SleepTimerSheet(vm: vm),
    );
  }

  void _openQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _QueueSheet(),
    );
  }
}

class _PlayerScreenState {
  final MusicEntity? music;
  final bool isPlaying;
  final double volume;

  const _PlayerScreenState({
    required this.music,
    required this.isPlaying,
    required this.volume,
  });

  @override
  bool operator ==(Object other) {
    return other is _PlayerScreenState &&
        other.music == music &&
        other.isPlaying == isPlaying &&
        other.volume == volume;
  }

  @override
  int get hashCode => Object.hash(music, isPlaying, volume);
}

class _PlayerSideSheet extends StatelessWidget {
  final Widget child;

  const _PlayerSideSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = (MediaQuery.of(context).size.width / _PlayerLayout.phi)
        .clamp(280.0, 520.0)
        .toDouble();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: _PlayerLayout.spaceSm),
        padding: const EdgeInsets.symmetric(vertical: _PlayerLayout.spaceMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(_PlayerLayout.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: _PlayerLayout.shadowBlurLg,
              offset: const Offset(-6, 8),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const _PressableScale({
    required this.child,
    required this.onTap,
    this.scale = _PlayerLayout.pressScale,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
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
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Padding(padding: const EdgeInsets.all(8), child: widget.child),
      ),
    );
  }
}

class _PlayerControlsSheet extends StatelessWidget {
  final VoidCallback onOpenSpeed;
  final VoidCallback onOpenTimer;
  final VoidCallback onOpenQueue;

  const _PlayerControlsSheet({
    required this.onOpenSpeed,
    required this.onOpenTimer,
    required this.onOpenQueue,
  });

  String _formatBadge(Duration? remaining) {
    if (remaining == null) return '';
    final totalSeconds = remaining.inSeconds;
    if (totalSeconds <= 0) return '0';
    final minutes = remaining.inMinutes;
    if (minutes >= 60) {
      final hours = (minutes / 60).floor();
      final mins = minutes % 60;
      return mins == 0 ? '${hours}h' : '${hours}h${mins}m';
    }
    if (minutes >= 1) return '${minutes}m';
    return '${totalSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<PlaylistViewModel>(
      builder: (context, vm, _) {
        final badgeText = vm.hasSleepTimer
            ? _formatBadge(vm.sleepRemaining)
            : '';
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            _PlayerLayout.spaceLg,
            _PlayerLayout.spaceSm,
            _PlayerLayout.spaceLg,
            _PlayerLayout.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _PlayerLayout.handleWidth,
                height: _PlayerLayout.handleHeight,
                margin: const EdgeInsets.only(bottom: _PlayerLayout.spaceMd),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(_PlayerLayout.radiusPill),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ShuffleButton(
                    isActive: vm.isShuffled,
                    onTap: vm.toggleShuffle,
                  ),
                  RepeatButton(mode: vm.repeatMode, onTap: vm.toggleRepeatMode),
                  SpeedButton(speed: vm.currentSpeed, onTap: onOpenSpeed),
                ],
              ),
              const SizedBox(height: _PlayerLayout.spaceMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PressableScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                    },
                    child: const Icon(Icons.equalizer),
                  ),
                  _PressableScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onOpenTimer();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.timer),
                        if (vm.hasSleepTimer)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                badgeText,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _PressableScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onOpenQueue();
                    },
                    child: const Icon(Icons.queue_music),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    return Consumer<PlaylistViewModel>(
      builder: (context, queueVm, _) {
        final queue = queueVm.musics;
        final currentIndex = queueVm.player.currentIndex ?? 0;

        return SizedBox(
          height: maxHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
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
                  'Fila de reprodução',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arraste para reordenar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                if (queue.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Fila vazia',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: queue.length,
                      onReorder: (oldIndex, newIndex) async {
                        HapticFeedback.lightImpact();
                        await queueVm.reorderQueue(oldIndex, newIndex);
                      },
                      buildDefaultDragHandles: false,
                      itemBuilder: (context, index) {
                        final music = queue[index];
                        final isCurrent = index == currentIndex;

                        return Container(
                          key: ValueKey('queue-item-${music.audioUrl}'),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  )
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.35,
                                    )
                                  : theme.colorScheme.outline.withValues(
                                      alpha: 0.15,
                                    ),
                            ),
                          ),
                          child: ListTile(
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await queueVm.playMusic(queueVm.musics, index);
                              if (context.mounted) Navigator.of(context).pop();
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrent)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.equalizer_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    Icons.drag_handle_rounded,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

class _SleepTimerSheet extends StatefulWidget {
  final PlaylistViewModel vm;

  const _SleepTimerSheet({required this.vm});

  @override
  State<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<_SleepTimerSheet> {
  final TextEditingController _minutesController = TextEditingController();

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  void _setMinutes(int minutes) {
    if (minutes <= 0) return;
    widget.vm.setSleepTimer(Duration(minutes: minutes));
    Navigator.of(context).pop();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presets = [5, 10, 15, 30, 60];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _PlayerLayout.spaceLg,
          _PlayerLayout.spaceSm,
          _PlayerLayout.spaceLg,
          _PlayerLayout.spaceLg + MediaQuery.of(context).viewInsets.bottom,
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
                            ? 'Ativo até o fim da música'
                            : mode == SleepTimerMode.endOfPlaylist
                            ? 'Ativo até o fim da playlist'
                            : 'Ativo')
                      : 'Escolha um tempo para parar a música',
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
                      onSelected: (_) => _setMinutes(m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Fim da música'),
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
                    labelText: 'Digite o número de minutos',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _PlayerLayout.radiusMd,
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    final minutes = int.tryParse(value.trim());
                    if (minutes != null) _setMinutes(minutes);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final minutes = int.tryParse(
                            _minutesController.text.trim(),
                          );
                          if (minutes != null) _setMinutes(minutes);
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
      ),
    );
  }
}

/// =======================================================
/// BACKGROUND COM BLUR DA CAPA
/// =======================================================

class _BackgroundArtwork extends StatelessWidget {
  final MusicEntity music;

  const _BackgroundArtwork({required this.music});

  @override
  Widget build(BuildContext context) {
    final image = music.artworkUrl;

    if (image == null) {
      return Container(color: Theme.of(context).scaffoldBackgroundColor);
    }

    ArtworkCache.preload(context, image);
    final provider = ArtworkCache.provider(image);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (provider != null) Image(image: provider, fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),
      ],
    );
  }
}

/// =======================================================
/// CAPA
/// =======================================================

class _ArtworkCover extends StatefulWidget {
  final MusicEntity music;

  const _ArtworkCover({required this.music});

  @override
  State<_ArtworkCover> createState() => _ArtworkCoverState();
}

class _ArtworkCoverState extends State<_ArtworkCover> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  Future<Uint8List?>? _artworkFuture;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant _ArtworkCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldArtworkId = oldWidget.music.sourceId ?? oldWidget.music.id;
    final newArtworkId = widget.music.sourceId ?? widget.music.id;
    if (oldArtworkId != newArtworkId) {
      _loadArtwork();
    }
  }

  void _loadArtwork() {
    final id = widget.music.sourceId ?? widget.music.id;
    if (id == null) {
      _artworkFuture = Future<Uint8List?>.value(null);
      return;
    }
    _artworkFuture = _audioQuery.queryArtwork(id, ArtworkType.AUDIO);
  }

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.of(context).size.width * _PlayerLayout.coverRatio)
        .clamp(_PlayerLayout.coverMinSize, _PlayerLayout.coverMaxSize)
        .toDouble();
    final theme = Theme.of(context);
    final shadows = theme.extension<AppShadows>();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_PlayerLayout.radiusXl),
        boxShadow: [
          ...(shadows?.elevated ?? const []),
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.45),
            blurRadius: _PlayerLayout.shadowBlurXl,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_PlayerLayout.radiusXl),
        child: FutureBuilder<Uint8List?>(
          future: _artworkFuture,
          builder: (context, snapshot) {
            Widget child;

            // sem capa
            if (!snapshot.hasData || snapshot.data == null) {
              child = Container(
                key: const ValueKey('no-artwork'),
                color: Colors.grey.shade900,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.music_note,
                  size: 90,
                  color: Colors.white70,
                ),
              );
            } else {
              child = Image.memory(
                snapshot.data!,
                key: ValueKey(widget.music.sourceId ?? widget.music.id),
                fit: BoxFit.cover,
              );
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _PlayerLayout {
  static const double phi = 1.618;

  // Modular spacing scale
  static const double spaceXs = 6;
  static const double spaceSm = 10;
  static const double spaceMd = 16;
  static const double spaceLg = 20;
  static const double spaceL = 28;
  static const double spaceXl = 32;

  // Controls and gestures
  static const double pressScale = 0.98;
  static const double transportIconSize = 36;
  static const double playButtonSize = 80;
  static const double volumeSliderBottomOffset = 120;

  // Shape
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusPill = 20;

  // Depth
  static const double shadowBlurLg = 24;
  static const double shadowBlurXl = 40;

  // Handles
  static const double handleWidth = 40;
  static const double handleHeight = 4;

  // Cover sizing (golden-inspired with device clamp)
  static const double coverRatio = 0.72;
  static const double coverMinSize = 220;
  static const double coverMaxSize = 460;
}
