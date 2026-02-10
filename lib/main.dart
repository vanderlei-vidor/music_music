import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_music/core/platform/desktop_init.dart';
import 'package:music_music/data/remote/database_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:music_music/app/app.dart';
import 'package:music_music/core/theme/theme_manager.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';

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

  final preset = await ThemeManager.loadPreset();
  final maxEntries = _artworkCacheMaxEntries(preset);
  ArtworkCache.configure(maxEntries: maxEntries);
  runApp(MusicApp(initialPreset: preset));
}

int _artworkCacheMaxEntries(ThemePreset preset) {
  final isDark = preset == ThemePreset.neumorphicDark;

  if (kIsWeb) return isDark ? 220 : 180;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Conservador por causa de dispositivos mais antigos (ex.: Android 9)
      return isDark ? 180 : 140;
    case TargetPlatform.iOS:
      return isDark ? 220 : 180;
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return isDark ? 260 : 220;
    default:
      return isDark ? 200 : 160;
  }
}

