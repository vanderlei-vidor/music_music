import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_music/core/theme/theme_manager.dart';
import 'package:music_music/core/preferences/podcast_preferences.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/features/player/view_model/player_panel_controller.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/app/app_info.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MusicApp extends StatelessWidget {
  final List<NavigatorObserver>? navigatorObservers;
  final ThemePreset? initialPreset;

  const MusicApp({
    super.key,
    this.navigatorObservers,
    this.initialPreset,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeManager(initialPreset: initialPreset),
        ),
        ChangeNotifierProvider(create: (_) => PodcastPreferences()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => PlaylistViewModel()),
        ChangeNotifierProvider(create: (_) => PlayerPanelController()),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, _) {
          return MaterialApp(
            title: AppInfo.appName,
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            themeMode: themeManager.themeMode,
            theme: ThemeManager.lightTheme,
            darkTheme: ThemeManager.darkTheme,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            routes: AppRoutes.baseRoutes,
            navigatorObservers:
                navigatorObservers ?? [AppRoutes.routeObserver],
          );
        },
      ),
    );
  }
}
