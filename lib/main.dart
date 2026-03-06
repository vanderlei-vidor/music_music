import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_music/app/app.dart';
import 'package:music_music/core/observability/app_logger.dart';
import 'package:music_music/core/platform/desktop_init.dart';
import 'package:music_music/core/theme/theme_manager.dart';
import 'package:music_music/data/remote/database_web.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLogger.error(
      'FlutterError',
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(
      'PlatformDispatcher',
      'Unhandled platform error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  await runZonedGuarded(
    () async {
      await _bootstrapApp();
    },
    (error, stack) {
      AppLogger.error(
        'Zone',
        'Unhandled zone error',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

Future<void> _bootstrapApp() async {
  // WEB
  if (kIsWeb) {
    initWebDatabase();
  }

  // DESKTOP: only here use FFI.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initDesktop();
  }

  // MOBILE: lockscreen + notification controls.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.music_music.playback',
      androidNotificationChannelName: 'Reproducao',
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
      // Conservative on older devices.
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
