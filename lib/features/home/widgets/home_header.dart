import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_music/core/ui/responsive.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';

class HomeHeader extends StatefulWidget {
  final bool canPlay;
  final String userName;
  final String? featuredTitle;
  final String? featuredSubtitle;
  final String? featuredArtwork;
  final int? featuredId;
  final Future<void> Function()? onPlayAll;
  final Future<void> Function()? onShuffleAll;
  final VoidCallback? onCycleFeatured;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    required this.canPlay,
    required this.userName,
    this.featuredTitle,
    this.featuredSubtitle,
    this.featuredArtwork,
    this.featuredId,
    this.onPlayAll,
    this.onShuffleAll,
    this.onCycleFeatured,
    this.onAvatarTap,
    this.onOpenDrawer,
    this.onOpenSettings,
    this.onSearchTap,
    this.onNotificationTap,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final Animation<double> _turns;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _turns = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  String _periodLabel() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Future<void> _onCycleTap() async {
    await _rotateController.forward(from: 0);
    widget.onCycleFeatured?.call();
  }

  void _openFeaturedSheet({
    required String title,
    required String subtitle,
    required double artworkSize,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return _FeaturedDetailsSheet(
          title: title,
          subtitle: subtitle,
          artworkUrl: widget.featuredArtwork,
          audioId: widget.featuredId,
          artworkSize: artworkSize,
          canPlay: widget.canPlay,
          onPlayAll: widget.onPlayAll,
          onShuffleAll: widget.onShuffleAll,
          onCycleFeatured: widget.onCycleFeatured,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizeClass = Responsive.of(context);
    final pagePadding = Responsive.value(
      context,
      compact: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      medium: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      expanded: const EdgeInsets.fromLTRB(22, 12, 22, 10),
    );
    final cardPadding = Responsive.value(
      context,
      compact: 11.0,
      medium: 12.0,
      expanded: 13.0,
    );
    final artworkSize = Responsive.value(
      context,
      compact: 74.0,
      medium: 84.0,
      expanded: 94.0,
    );
    final avatarSize = Responsive.value(
      context,
      compact: 42.0,
      medium: 46.0,
      expanded: 50.0,
    );
    final greeting = _periodLabel();
    final title = widget.featuredTitle ?? 'Sua trilha de hoje';
    final subtitle =
        widget.featuredSubtitle ??
        'Use a busca no topo para achar musicas, artistas e albuns.';
    final isFeaturedCompact =
        sizeClass == SizeClass.compact ||
        MediaQuery.of(context).size.height < 760;

    return Padding(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: widget.onOpenDrawer,
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menu',
              ),
              _UserAvatar(
                name: widget.userName,
                onTap: widget.onAvatarTap,
                size: avatarSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(text: '$greeting, '),
                      TextSpan(
                        text: widget.userName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const TextSpan(text: '!'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Configuracoes',
              ),
              IconButton(
                onPressed: widget.onSearchTap,
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Buscar',
              ),
              IconButton(
                onPressed: widget.onNotificationTap,
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Notificacoes',
              ),
            ],
          ),
          SizedBox(height: sizeClass == SizeClass.compact ? 8 : 10),
          if (isFeaturedCompact)
            _FeaturedCompactCard(
              title: title,
              subtitle: subtitle,
              artworkUrl: widget.featuredArtwork,
              audioId: widget.featuredId,
              artworkSize: 54,
              onTap: () => _openFeaturedSheet(
                title: title,
                subtitle: subtitle,
                artworkSize: artworkSize,
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.98),
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.9,
                    ),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Destaque do dia',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Trocar destaque',
                              visualDensity: VisualDensity.compact,
                              onPressed: widget.onCycleFeatured == null
                                  ? null
                                  : _onCycleTap,
                              icon: RotationTransition(
                                turns: Tween<double>(
                                  begin: 0,
                                  end: 0.75,
                                ).animate(_turns),
                                child: const Icon(Icons.autorenew_rounded),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            title,
                            key: ValueKey('featured-title-$title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            subtitle,
                            key: ValueKey('featured-subtitle-$subtitle'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: sizeClass == SizeClass.compact ? 6 : 8,
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            FilledButton(
                              onPressed: widget.canPlay
                                  ? () => widget.onPlayAll?.call()
                                  : null,
                              style: FilledButton.styleFrom(
                                shape: const StadiumBorder(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: sizeClass == SizeClass.compact
                                      ? 12
                                      : 16,
                                  vertical: sizeClass == SizeClass.compact
                                      ? 8
                                      : 10,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Tocar tudo'),
                            ),
                            TextButton(
                              onPressed: widget.canPlay
                                  ? () => widget.onShuffleAll?.call()
                                  : null,
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                backgroundColor: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.09),
                                shape: const StadiumBorder(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: sizeClass == SizeClass.compact
                                      ? 12
                                      : 16,
                                  vertical: sizeClass == SizeClass.compact
                                      ? 8
                                      : 10,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Aleatorio'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: sizeClass == SizeClass.compact ? 12 : 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _FeaturedArtwork(
                      key: ValueKey(
                        'featured-artwork-${widget.featuredArtwork ?? "none"}',
                      ),
                      artworkUrl: widget.featuredArtwork,
                      audioId: widget.featuredId,
                      size: artworkSize,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedCompactCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? artworkUrl;
  final int? audioId;
  final double artworkSize;
  final VoidCallback onTap;

  const _FeaturedCompactCard({
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.audioId,
    required this.artworkSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface.withValues(alpha: 0.92),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              _FeaturedArtwork(
                artworkUrl: artworkUrl,
                audioId: audioId,
                size: artworkSize,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destaque do dia',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedDetailsSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? artworkUrl;
  final int? audioId;
  final double artworkSize;
  final bool canPlay;
  final Future<void> Function()? onPlayAll;
  final Future<void> Function()? onShuffleAll;
  final VoidCallback? onCycleFeatured;

  const _FeaturedDetailsSheet({
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.audioId,
    required this.artworkSize,
    required this.canPlay,
    this.onPlayAll,
    this.onShuffleAll,
    this.onCycleFeatured,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Row(
            children: [
              _FeaturedArtwork(
                artworkUrl: artworkUrl,
                audioId: audioId,
                size: artworkSize * 0.72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destaque do dia',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Trocar destaque',
                onPressed: () {
                  Navigator.of(context).pop();
                  onCycleFeatured?.call();
                },
                icon: const Icon(Icons.autorenew_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: canPlay ? () => onPlayAll?.call() : null,
                  child: const Text('Tocar tudo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: canPlay ? () => onShuffleAll?.call() : null,
                  child: const Text('Aleatorio'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedArtwork extends StatelessWidget {
  final String? artworkUrl;
  final int? audioId;
  final double size;

  const _FeaturedArtwork({
    super.key,
    required this.artworkUrl,
    this.audioId,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ArtworkCache.preload(context, artworkUrl);
    final provider = ArtworkCache.provider(artworkUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: provider != null
            ? Image(
                image: provider,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _fallback(theme),
              )
            : (!kIsWeb && audioId != null)
            ? QueryArtworkWidget(
                id: audioId!,
                type: ArtworkType.AUDIO,
                artworkFit: BoxFit.cover,
                nullArtworkWidget: _fallback(theme),
              )
            : _fallback(theme),
      ),
    );
  }

  Widget _fallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.album_rounded, color: theme.colorScheme.primary),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;
  final double size;

  const _UserAvatar({required this.name, this.onTap, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? 'U' : trimmed[0].toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
