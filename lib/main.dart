// main.dart
import 'dart:io'; // Import for platform check
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:window_manager/window_manager.dart'; // Import for desktop window

import 'core/theme/app_colors.dart';
import 'views/splash/splash_view.dart';
import 'views/playlist/playlist_view_model.dart';
import 'views/home/home_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up the window for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
    // ✅ Inicializa o just_audio_background APENAS em mobile
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.music_music.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ CORRECTED: HomeViewModel no longer gets OnAudioQuery passed to it.
        // It should handle music fetching internally using your MusicService.
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => PlaylistViewModel()),
      ],
      child: MaterialApp(
        title: 'Music Music',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const SplashView(),
      ),
    );
  }
}