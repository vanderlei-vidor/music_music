import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_music/core/platform/desktop_init.dart';
import 'package:music_music/data/remote/database_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:music_music/app/app.dart';

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

  // 📲 MOBILE: lockscreen + notification controls
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.music_music.playback',
      androidNotificationChannelName: 'Reprodução',
      androidNotificationOngoing: true,
    );
  }

  runApp(const MusicApp());
}

