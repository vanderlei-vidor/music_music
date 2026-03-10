import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_music/app/app.dart';
import 'package:music_music/core/audio/audio_service_controller.dart';
import 'package:music_music/core/observability/app_logger.dart';
import 'package:music_music/core/platform/desktop_init.dart';
import 'package:music_music/core/services/music_widget_manager.dart';
import 'package:music_music/core/theme/theme_manager.dart';
import 'package:music_music/data/remote/database_web.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
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

      _widgetActionController = StreamController<String>.broadcast(
        onListen: _flushBufferedWidgetActions,
      );
      _setupWidgetActionChannel();
      await _loadPendingWidgetAction();

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

/// Setup Method Channel para ações dos widgets
void _setupWidgetActionChannel() {
  const channel = MethodChannel('com.example.music_music/widget_actions');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'onWidgetAction') {
      final action = call.arguments as String;
      debugPrint('🏠 Widget action recebida: $action');
      
      // Envia evento para o PlaylistViewModel via EventChannel ou Provider
      // O listener será registrado no app.dart
      _emitWidgetAction(action);
    }
  });
}

// Controller para ações dos widgets
StreamController<String>? _widgetActionController;
final List<String> _bufferedWidgetActions = <String>[];

StreamController<String>? get widgetActionController => _widgetActionController;

void _emitWidgetAction(String action) {
  if (_widgetActionController?.hasListener ?? false) {
    _widgetActionController?.add(action);
    return;
  }
  _bufferedWidgetActions.add(action);
}

void _flushBufferedWidgetActions() {
  while (_bufferedWidgetActions.isNotEmpty) {
    _widgetActionController?.add(_bufferedWidgetActions.removeAt(0));
  }
}

Future<void> _loadPendingWidgetAction() async {
  const channel = MethodChannel('com.example.music_music/widget_actions');
  try {
    final action = await channel.invokeMethod<String>('getPendingWidgetAction');
    if (action != null && action.isNotEmpty) {
      debugPrint('Widget action pendente carregada: $action');
      _emitWidgetAction(action);
    }
  } catch (_) {
    // Ignora em plataformas sem implementaÃ§Ã£o nativa.
  }
}

Future<void> _bootstrapApp() async {
  // WEB
  if (kIsWeb) {
    initWebDatabase();
  }

  await AudioServiceController.init();

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
    // 🏠 Inicializar Widget de Home Screen
    await MusicWidgetManager.initialize();
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

