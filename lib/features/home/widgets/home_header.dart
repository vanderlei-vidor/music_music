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
  final VoidCallback? onOpenSettings;
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
    this.onOpenSettings,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizeClass = Responsive.of(context);
    final pagePadding = Responsive.value(
      context,
      compact: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      medium: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      expanded: const EdgeInsets.fromLTRB(28, 20, 28, 16),
    );
    final cardPadding = Responsive.value(
      context,
      compact: 14.0,
      medium: 16.0,
      expanded: 18.0,
    );
    final artworkSize = Responsive.value(
      context,
      compact: 92.0,
      medium: 108.0,
      expanded: 120.0,
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
        'Abra o Buscar no menu inferior para achar musicas, artistas e albuns.';

    return Padding(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                onPressed: widget.onNotificationTap,
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Notificacoes',
              ),
            ],
          ),
          SizedBox(height: sizeClass == SizeClass.compact ? 14 : 16),
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
                      const SizedBox(height: 6),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: sizeClass == SizeClass.compact ? 12 : 14,
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton(
                            onPressed: widget.canPlay
                                ? () => widget.onPlayAll?.call()
                                : null,
                            style: FilledButton.styleFrom(
                              shape: const StadiumBorder(),
                              padding: EdgeInsets.symmetric(
                                horizontal: sizeClass == SizeClass.compact
                                    ? 18
                                    : 20,
                                vertical: sizeClass == SizeClass.compact
                                    ? 12
                                    : 13,
                              ),
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
                                    ? 18
                                    : 20,
                                vertical: sizeClass == SizeClass.compact
                                    ? 12
                                    : 13,
                              ),
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
