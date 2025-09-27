// main.dart
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:window_manager/window_manager.dart'; 
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'core/theme/theme_manager.dart'; // 👈 Importe o novo ThemeManager
import 'views/splash/splash_view.dart';
import 'views/playlist/playlist_view_model.dart';
import 'views/home/home_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MetadataGod.initialize();
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      minimumSize: Size(600, 400),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.music_music.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
    );
  }
  debugPaintSizeEnabled = false;
  runApp(const MusicApp()); // 👈 Renomeei para MusicApp para clareza
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()), // 👈 Adicionado o ThemeManager
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => PlaylistViewModel()),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            title: 'Music Music',
            debugShowCheckedModeBanner: false,
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