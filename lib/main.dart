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

import 'core/theme/app_colors.dart';
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
            // 💡 Define o tema baseado no ThemeManager
            themeMode: themeManager.themeMode, 
            // 💡 Tema Claro
            theme: ThemeData.light(useMaterial3: true).copyWith(
              // Exemplo: Cores personalizadas para o tema claro
              scaffoldBackgroundColor: const Color(0xFFF0F0F0),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF5D3FD3), // Cor primária
                secondary: Color(0xFF7B66FF), // Cor de destaque
                background: Color(0xFFF0F0F0),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              // Adicione mais customizações de light theme aqui...
            ),
            // 💡 Tema Escuro
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              // Exemplo: Cores personalizadas para o tema escuro
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primaryPurple,
                secondary: AppColors.accentPurple,
                background: AppColors.background,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.background,
                foregroundColor: Colors.white,
              ),
              // Adicione mais customizações de dark theme aqui...
            ),
            home: const SplashView(),
          );
        },
      ),
    );
  }
}