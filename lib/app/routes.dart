import 'package:flutter/material.dart';

import 'package:music_music/features/favorites/view/favorites_view.dart';
import 'package:music_music/features/folders/view/folder_detail_view.dart';
import 'package:music_music/features/folders/view/folders_view.dart';
import 'package:music_music/features/genres/view/genre_detail_view.dart';
import 'package:music_music/features/genres/view/genres_view.dart';
import 'package:music_music/features/history/view/most_played_view.dart';
import 'package:music_music/features/history/view/recent_view.dart';
import 'package:music_music/features/home/view/home_screen.dart';
import 'package:music_music/features/library/view/album_detail_screen.dart';
import 'package:music_music/features/library/view/artist_detail_screen.dart';
import 'package:music_music/features/player/view/player_view.dart';
import 'package:music_music/features/playlists/view/playlist_view.dart';
import 'package:music_music/features/playlists/view/music_selection_screen.dart';
import 'package:music_music/features/playlists/view/playlist_detail_screen.dart';
import 'package:music_music/features/playlists/view/playlists_screen.dart';
import 'package:music_music/features/splash/view/splash_view.dart';
import 'package:music_music/features/settings/view/theme_settings_view.dart';
import 'package:music_music/data/models/music_entity.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const player = '/player';
  static const playlists = '/playlists';
  static const playlistView = '/library';
  static const themes = '/themes';
  static const favorites = '/favorites';
  static const folders = '/folders';
  static const folderDetail = '/folder';
  static const genres = '/genres';
  static const genreDetail = '/genre';
  static const recent = '/recent';
  static const mostPlayed = '/most-played';
  static const albumDetail = '/album';
  static const artistDetail = '/artist';
  static const playlistDetail = '/playlist';
  static const musicSelection = '/playlist/add';

  static final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();

  static final Map<String, WidgetBuilder> baseRoutes = {
    splash: (_) => const SplashView(),
    home: (_) => const HomeScreen(),
    player: (_) => const PlayerView(),
    playlists: (_) => const PlaylistsScreen(),
    playlistView: (_) => const PlaylistView(),
    themes: (_) => const ThemeSettingsView(),
    favorites: (_) => const FavoritesView(),
    folders: (_) => const FoldersView(),
    genres: (_) => const GenresView(),
    recent: (_) => const RecentMusicsView(),
    mostPlayed: (_) => const MostPlayedView(),
  };

  static Widget? buildBasePage(String name) {
    switch (name) {
      case splash:
        return const SplashView();
      case home:
        return const HomeScreen();
      case player:
        return const PlayerView();
      case playlists:
        return const PlaylistsScreen();
      case playlistView:
        return const PlaylistView();
      case themes:
        return const ThemeSettingsView();
      case favorites:
        return const FavoritesView();
      case folders:
        return const FoldersView();
      case genres:
        return const GenresView();
      case recent:
        return const RecentMusicsView();
      case mostPlayed:
        return const MostPlayedView();
    }
    return null;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    final args = settings.arguments;

    switch (name) {
      case folderDetail:
        if (args is FolderDetailArgs) {
          return _slideRoute(
            settings,
            FolderDetailView(folderName: args.folderName, musics: args.musics),
          );
        }
        break;

      case genreDetail:
        if (args is GenreDetailArgs) {
          return _slideRoute(
            settings,
            GenreDetailView(genre: args.genre, musics: args.musics),
          );
        }
        break;

      case albumDetail:
        if (args is AlbumDetailArgs) {
          return _slideRoute(
            settings,
            AlbumDetailScreen(albumName: args.albumName),
          );
        }
        break;

      case artistDetail:
        if (args is ArtistDetailArgs) {
          return _slideRoute(
            settings,
            ArtistDetailView(artistName: args.artistName),
          );
        }
        break;

      case playlistDetail:
        if (args is PlaylistDetailArgs) {
          return _slideRoute(
            settings,
            PlaylistDetailScreen(
              playlistId: args.playlistId,
              playlistName: args.playlistName,
            ),
          );
        }
        break;

      case musicSelection:
        if (args is MusicSelectionArgs) {
          return _slideRoute(
            settings,
            MusicSelectionScreen(
              playlistId: args.playlistId,
              playlistName: args.playlistName,
            ),
          );
        }
        break;
    }

    final basePage = buildBasePage(name);
    if (basePage != null) {
      return _fadeRoute(settings, basePage);
    }

    return _fadeRoute(settings, _UnknownRoute(name: name));
  }
}

PageRoute<dynamic> _fadeRoute(RouteSettings settings, Widget page) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

PageRoute<dynamic> _slideRoute(RouteSettings settings, Widget page) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      final tween = Tween<Offset>(
        begin: const Offset(0.08, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: animation.drive(tween), child: child),
      );
    },
  );
}

class AlbumDetailArgs {
  final String albumName;
  const AlbumDetailArgs({required this.albumName});
}

class ArtistDetailArgs {
  final String artistName;
  const ArtistDetailArgs({required this.artistName});
}

class PlaylistDetailArgs {
  final int playlistId;
  final String playlistName;
  const PlaylistDetailArgs({
    required this.playlistId,
    required this.playlistName,
  });
}

class MusicSelectionArgs {
  final int playlistId;
  final String playlistName;
  const MusicSelectionArgs({
    required this.playlistId,
    required this.playlistName,
  });
}

class GenreDetailArgs {
  final String genre;
  final List<MusicEntity> musics;
  const GenreDetailArgs({required this.genre, required this.musics});
}

class FolderDetailArgs {
  final String folderName;
  final List<MusicEntity> musics;
  const FolderDetailArgs({required this.folderName, required this.musics});
}

class _UnknownRoute extends StatelessWidget {
  final String name;
  const _UnknownRoute({required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rota n\u00e3o encontrada')),
      body: Center(
        child: Text('Rota n\u00e3o registrada: $name'),
      ),
    );
  }
}
