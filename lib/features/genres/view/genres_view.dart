import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/features/genres/widgets/genre_card.dart';

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
    final musics = context.watch<PlaylistViewModel>().musics;

    final Map<String, List<MusicEntity>> genres = {};

    for (final m in musics) {
      final genre =
          (m.genre == null || m.genre!.isEmpty) ? 'Desconhecido' : m.genre!;

      genres.putIfAbsent(genre, () => []).add(m);
    }

    final genreNames = genres.keys.toList()..sort();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: genreNames.length,
      itemBuilder: (context, index) {
        final genre = genreNames[index];
        final genreMusics = genres[genre]!;

        return AnimatedBuilder(
          animation: _controller,
          child: Hero(
            tag: 'genre_$genre',
            child: Material(
              color: Colors.transparent,
              child: GenreCard(
                genre: genre,
                count: genreMusics.length,
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


