import 'dart:io';
import 'package:music_music/core/ios_upload/ios_music_scanner.dart';

import 'music_scanner.dart';
import 'android_music_scanner.dart';

import 'desktop_music_scanner.dart';

MusicScanner getMusicScanner() {
  if (Platform.isAndroid) return AndroidMusicScanner();
  if (Platform.isIOS) return IOSMusicScanner();
  if (Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS) {
    return DesktopMusicScanner();
  }

  throw UnsupportedError('Plataforma não suportada');
}
