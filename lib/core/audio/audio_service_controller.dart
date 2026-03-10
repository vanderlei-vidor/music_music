import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import 'package:music_music/core/audio/app_audio_handler.dart';
import 'package:music_music/features/player/equalizer/equalizer_backend.dart';

class AudioServiceController {
  static AudioHandler? _handler;

  static AudioHandler get handler => _handler!;

  static Future<void> init() async {
    if (_handler != null) return;
    final backend = createPlatformEqualizerBackend();
    final player = createAudioPlayerForBackend(backend);
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _handler = AppAudioHandler(player: player, eqBackend: backend);
      return;
    }

    _handler = await AudioService.init(
      builder: () => AppAudioHandler(player: player, eqBackend: backend),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_music.playback',
        androidNotificationChannelName: 'Reproducao',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }
}
