import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
        final vm = PlaylistViewModel(player: AudioPlayer());

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
