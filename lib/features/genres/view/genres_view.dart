import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/features/genres/widgets/genre_card.dart';
import 'package:music_music/shared/widgets/skeleton.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/core/ui/responsive.dart';

class GenresView extends StatefulWidget {
  const GenresView({super.key});

  @override
  State<GenresView> createState() => _GenresViewState();
}

class _GenresViewState extends State<GenresView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musics = context.watch<HomeViewModel>().musics;

    final Map<String, List<MusicEntity>> genres = {};

    for (final m in musics) {
      final genre = (m.genre == null || m.genre!.isEmpty)
          ? 'Desconhecido'
          : m.genre!;

      genres.putIfAbsent(genre, () => []).add(m);
    }

    final genreNames = genres.keys.toList()..sort();
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
    final mainExtent =
        Responsive.value(
          context,
          compact: 186.0,
          medium: 198.0,
          expanded: 208.0,
        ) +
        ((MediaQuery.textScalerOf(context).scale(1.0) - 1.0).clamp(0.0, 0.6) *
            34);

    if (genreNames.isEmpty) {
      return const _GenresSkeleton();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        mainAxisExtent: mainExtent,
      ),
      itemCount: genreNames.length,
      itemBuilder: (context, index) {
        final genre = genreNames[index];
        final genreMusics = genres[genre]!;
        final cover = genreMusics.isEmpty ? null : genreMusics.first;

        return AnimatedBuilder(
          animation: _controller,
          child: Hero(
            tag: 'genre_$genre',
            child: Material(
              color: Colors.transparent,
              child: GenreCard(
                genre: genre,
                count: genreMusics.length,
                artworkUrl: cover?.artworkUrl,
                audioId: cover == null ? null : (cover.sourceId ?? cover.id),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.genreDetail,
                    arguments: GenreDetailArgs(
                      genre: genre,
                      musics: genreMusics,
                    ),
                  );
                },
              ),
            ),
          ),
          builder: (context, child) {
            final animation = CurvedAnimation(
              parent: _controller,
              curve: Interval(
                (index / genreNames.length).clamp(0.0, 1.0),
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

class _GenresSkeleton extends StatelessWidget {
  const _GenresSkeleton();

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
      compact: 186.0,
      medium: 198.0,
      expanded: 208.0,
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
