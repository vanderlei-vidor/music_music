import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_music/core/platform/desktop_init.dart';
import 'package:music_music/data/database_web.dart';

import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'views/splash/splash_view.dart';
import 'views/playlist/playlist_view_model.dart';
import 'views/home/home_view_model.dart';
import 'views/player/player_panel_controller.dart';
import 'core/theme/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌐 WEB
  if (kIsWeb) {
    initWebDatabase();
  }

  // 🖥️ DESKTOP (somente aqui usa FFI)
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {

    // ✅ SQLite FFI apenas no desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await initDesktop();
  }

  runApp(const MusicApp());
}


final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => PlaylistViewModel()),
        ChangeNotifierProvider(create: (_) => PlayerPanelController()),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, _) {
          return MaterialApp(
            title: 'Music Music',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            themeMode: themeManager.themeMode,
            theme: ThemeManager.lightTheme,
            darkTheme: ThemeManager.darkTheme,
            home: const SplashView(),
          );
        },
      ),
    );
  }
}
