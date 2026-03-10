import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:audio_service/audio_service.dart';

class TestAudioHandler extends BaseAudioHandler {
  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    this.queue.add(queue);
  }

  @override
  Future<void> skipToQueueItem(int index) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> setSpeed(double speed) async {
    playbackState.add(playbackState.value.copyWith(speed: speed));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets(
    'PlaylistViewModel dispose nao gera erro assincrono apos listeners iniciados',
    (_) async {
      final uncaughtErrors = <Object>[];

      await runZonedGuarded(() async {
        final vm = PlaylistViewModel(handler: TestAudioHandler());

        // Allow async setup/listeners to attach before disposal.
        await Future<void>.delayed(const Duration(milliseconds: 120));
        vm.dispose();

        // Keep the zone alive briefly to catch potential late async emissions.
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }, (error, stackTrace) {
        uncaughtErrors.add(error);
      });

      expect(uncaughtErrors, isEmpty);
    },
  );
}
