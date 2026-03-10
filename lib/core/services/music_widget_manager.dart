import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:music_music/data/models/music_entity.dart';

class MusicWidgetManager {
  static const String _groupId = 'group.com.example.musicmusic';

  static const String _widgetPlayer = 'MusicWidgetPlayer';
  static const String _widgetPlayer4x2 = 'MusicWidgetPlayer4x2';
  static const String _widgetPlayer2x2 = 'MusicWidgetPlayer2x2';
  static const String _widgetPlayer4x4 = 'MusicWidgetPlayer4x4';

  static const String _iosWidgetPlayer = 'PlayerWidget';
  static const Duration _updateDebounce = Duration(milliseconds: 220);

  static String _playerTitle = 'Nenhuma musica';
  static String _playerArtist = '-';
  static bool _playerIsPlaying = false;
  static bool _playerIsShuffled = false;
  static int _playerRepeatMode = 0;
  static bool _playerIsFavorite = false;
  static List<String> _playerQueue = <String>['-', '-', '-', '-'];
  static int _playerQueueCount = 0;
  static int _playerThemeColor = 0xFFFFE0A3;
  static int _playerQueueStartPosition = 1;
  static int _playerCurrentPosition = 1;
  static int _playerTotalTracks = 0;
  static String _playerQueueAllJson = '[]';

  static Timer? _updateTimer;
  static bool _updateInProgress = false;
  static bool _updateQueued = false;

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_groupId);
      debugPrint('MusicWidgetManager inicializado com widgets de player');
      await _initializeAllWidgets();
    } catch (e) {
      debugPrint('Erro ao inicializar widgets: $e');
    }
  }

  static Future<void> _initializeAllWidgets() async {
    await HomeWidget.saveWidgetData<String>('player_title', 'Nenhuma musica');
    await HomeWidget.saveWidgetData<String>('player_artist', '-');
    await HomeWidget.saveWidgetData<bool>('player_isPlaying', false);
    await HomeWidget.saveWidgetData<bool>('player_isShuffled', false);
    await HomeWidget.saveWidgetData<int>('player_repeatMode', 0);
    await HomeWidget.saveWidgetData<bool>('player_isFavorite', false);
    await HomeWidget.saveWidgetData<String>('player_queue_1', '-');
    await HomeWidget.saveWidgetData<String>('player_queue_2', '-');
    await HomeWidget.saveWidgetData<String>('player_queue_3', '-');
    await HomeWidget.saveWidgetData<String>('player_queue_4', '-');
    await HomeWidget.saveWidgetData<int>('player_queue_count', 0);
    await HomeWidget.saveWidgetData<int>('player_theme_color', _playerThemeColor);
    await HomeWidget.saveWidgetData<int>('player_queue_start_position', 1);
    await HomeWidget.saveWidgetData<int>('player_current_position', 1);
    await HomeWidget.saveWidgetData<int>('player_total_tracks', 0);
    await HomeWidget.saveWidgetData<String>('player_queue_all_json', '[]');

    _playerTitle = 'Nenhuma musica';
    _playerArtist = '-';
    _playerIsPlaying = false;
    _playerIsShuffled = false;
    _playerRepeatMode = 0;
    _playerIsFavorite = false;
    _playerQueue = <String>['-', '-', '-', '-'];
    _playerQueueCount = 0;
    _playerThemeColor = 0xFFFFE0A3;
    _playerQueueStartPosition = 1;
    _playerCurrentPosition = 1;
    _playerTotalTracks = 0;
    _playerQueueAllJson = '[]';
  }

  static Future<void> updatePlayerWidget({
    MusicEntity? currentMusic,
    bool isPlaying = false,
    String? artworkPath,
    bool isShuffled = false,
    int repeatMode = 0,
    bool isFavorite = false,
    List<String>? queueTitles,
    int? queueCount,
    int? themeColor,
    int? queueStartPosition,
    int? currentPosition,
    int? totalTracks,
  }) async {
    try {
      final title = currentMusic?.title ?? 'Nenhuma musica';
      final artist = currentMusic?.artist ?? '-';
      final queue = List<String>.generate(
        4,
        (i) => (queueTitles != null && i < queueTitles.length) ? queueTitles[i] : '-',
      );
      final queueAll = queueTitles ?? const <String>[];
      final queueAllJson = jsonEncode(queueAll);

      final totalQueueCount = queueCount ?? (queueTitles?.length ?? 0);
      final effectiveThemeColor = themeColor ?? _playerThemeColor;
      final effectiveQueueStartPosition = queueStartPosition ?? _playerQueueStartPosition;
      final effectiveCurrentPosition = currentPosition ?? _playerCurrentPosition;
      final effectiveTotalTracks = totalTracks ?? _playerTotalTracks;
      final hasChanges = title != _playerTitle ||
          artist != _playerArtist ||
          isPlaying != _playerIsPlaying ||
          isShuffled != _playerIsShuffled ||
          repeatMode != _playerRepeatMode ||
          isFavorite != _playerIsFavorite ||
          totalQueueCount != _playerQueueCount ||
          effectiveThemeColor != _playerThemeColor ||
          effectiveQueueStartPosition != _playerQueueStartPosition ||
          effectiveCurrentPosition != _playerCurrentPosition ||
          effectiveTotalTracks != _playerTotalTracks ||
          queueAllJson != _playerQueueAllJson ||
          !_listEquals(queue, _playerQueue);
      if (!hasChanges) return;

      await HomeWidget.saveWidgetData<String>('player_title', title);
      await HomeWidget.saveWidgetData<String>('player_artist', artist);
      await HomeWidget.saveWidgetData<bool>('player_isPlaying', isPlaying);
      await HomeWidget.saveWidgetData<String>('player_artworkPath', artworkPath ?? '');
      await HomeWidget.saveWidgetData<bool>('player_isShuffled', isShuffled);
      await HomeWidget.saveWidgetData<int>('player_repeatMode', repeatMode);
      await HomeWidget.saveWidgetData<bool>('player_isFavorite', isFavorite);
      await HomeWidget.saveWidgetData<String>('player_queue_1', queue[0]);
      await HomeWidget.saveWidgetData<String>('player_queue_2', queue[1]);
      await HomeWidget.saveWidgetData<String>('player_queue_3', queue[2]);
      await HomeWidget.saveWidgetData<String>('player_queue_4', queue[3]);
      await HomeWidget.saveWidgetData<int>('player_queue_count', totalQueueCount);
      await HomeWidget.saveWidgetData<int>('player_theme_color', effectiveThemeColor);
      await HomeWidget.saveWidgetData<int>(
        'player_queue_start_position',
        effectiveQueueStartPosition,
      );
      await HomeWidget.saveWidgetData<int>('player_current_position', effectiveCurrentPosition);
      await HomeWidget.saveWidgetData<int>('player_total_tracks', effectiveTotalTracks);
      await HomeWidget.saveWidgetData<String>('player_queue_all_json', queueAllJson);

      _playerTitle = title;
      _playerArtist = artist;
      _playerIsPlaying = isPlaying;
      _playerIsShuffled = isShuffled;
      _playerRepeatMode = repeatMode;
      _playerIsFavorite = isFavorite;
      _playerQueue = queue;
      _playerQueueCount = totalQueueCount;
      _playerThemeColor = effectiveThemeColor;
      _playerQueueStartPosition = effectiveQueueStartPosition;
      _playerCurrentPosition = effectiveCurrentPosition;
      _playerTotalTracks = effectiveTotalTracks;
      _playerQueueAllJson = queueAllJson;

      _requestPlayerWidgetsUpdate();
    } catch (e) {
      debugPrint('Erro ao atualizar widget player: $e');
    }
  }

  static Future<void> updatePlayerPlayPause(bool isPlaying) async {
    try {
      if (_playerIsPlaying == isPlaying) return;
      await HomeWidget.saveWidgetData<bool>('player_isPlaying', isPlaying);
      _playerIsPlaying = isPlaying;
      _requestPlayerWidgetsUpdate(urgent: true);
    } catch (e) {
      debugPrint('Erro ao atualizar play/pause: $e');
    }
  }

  static Future<void> updatePlayerControlsState({
    required bool isShuffled,
    required int repeatMode,
    required bool isFavorite,
  }) async {
    try {
      if (_playerIsShuffled == isShuffled &&
          _playerRepeatMode == repeatMode &&
          _playerIsFavorite == isFavorite) {
        return;
      }
      await HomeWidget.saveWidgetData<bool>('player_isShuffled', isShuffled);
      await HomeWidget.saveWidgetData<int>('player_repeatMode', repeatMode);
      await HomeWidget.saveWidgetData<bool>('player_isFavorite', isFavorite);
      _playerIsShuffled = isShuffled;
      _playerRepeatMode = repeatMode;
      _playerIsFavorite = isFavorite;
      _requestPlayerWidgetsUpdate();
    } catch (e) {
      debugPrint('Erro ao atualizar estado dos controles: $e');
    }
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static void _requestPlayerWidgetsUpdate({bool urgent = false}) {
    if (urgent) {
      _updateTimer?.cancel();
      _updateTimer = null;
      unawaited(_flushPlayerWidgetsUpdate());
      return;
    }

    _updateQueued = true;
    _updateTimer?.cancel();
    _updateTimer = Timer(_updateDebounce, () {
      unawaited(_flushPlayerWidgetsUpdate());
    });
  }

  static Future<void> _flushPlayerWidgetsUpdate() async {
    if (_updateInProgress) {
      _updateQueued = true;
      return;
    }
    _updateInProgress = true;
    _updateQueued = false;
    try {
      await _updatePlayerWidgets();
    } finally {
      _updateInProgress = false;
      if (_updateQueued) {
        _updateQueued = false;
        _requestPlayerWidgetsUpdate();
      }
    }
  }

  static Future<void> _updatePlayerWidgets() async {
    await _updateWidget(_widgetPlayer, _iosWidgetPlayer);
    await _updateWidget(_widgetPlayer4x2, _iosWidgetPlayer);
    await _updateWidget(_widgetPlayer2x2, _iosWidgetPlayer);
    await _updateWidget(_widgetPlayer4x4, _iosWidgetPlayer);
  }

  static Future<bool> _updateWidget(String name, String iOSName) async {
    try {
      final result = await HomeWidget.updateWidget(name: name, iOSName: iOSName);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static void registerClickCallback(Function(String?) callback) {
    HomeWidget.widgetClicked.listen((uri) {
      callback(uri?.toString());
    });
  }

  static Future<bool> isWidgetInstalled({required String widgetName}) async {
    return false;
  }

  static Future<Map<String, dynamic>> getWidgetData() async {
    try {
      final data = {
        'player_title': await HomeWidget.getWidgetData<String>('player_title'),
        'player_artist': await HomeWidget.getWidgetData<String>('player_artist'),
        'player_isPlaying': await HomeWidget.getWidgetData<bool>('player_isPlaying'),
        'player_isShuffled': await HomeWidget.getWidgetData<bool>('player_isShuffled'),
        'player_repeatMode': await HomeWidget.getWidgetData<int>('player_repeatMode'),
        'player_isFavorite': await HomeWidget.getWidgetData<bool>('player_isFavorite'),
        'player_queue_1': await HomeWidget.getWidgetData<String>('player_queue_1'),
        'player_queue_2': await HomeWidget.getWidgetData<String>('player_queue_2'),
        'player_queue_3': await HomeWidget.getWidgetData<String>('player_queue_3'),
        'player_queue_4': await HomeWidget.getWidgetData<String>('player_queue_4'),
        'player_queue_count': await HomeWidget.getWidgetData<int>('player_queue_count'),
        'player_theme_color': await HomeWidget.getWidgetData<int>('player_theme_color'),
        'player_queue_start_position': await HomeWidget.getWidgetData<int>(
          'player_queue_start_position',
        ),
        'player_current_position': await HomeWidget.getWidgetData<int>(
          'player_current_position',
        ),
        'player_total_tracks': await HomeWidget.getWidgetData<int>('player_total_tracks'),
        'player_queue_all_json': await HomeWidget.getWidgetData<String>('player_queue_all_json'),
      };
      return data;
    } catch (_) {
      return {};
    }
  }

  static Future<void> testWidgets() async {
    await updatePlayerWidget(
      currentMusic: MusicEntity(
        id: 999,
        title: 'Musica Teste',
        artist: 'Artista Teste',
        audioUrl: 'test://url',
      ),
      isPlaying: true,
      queueTitles: const <String>[
        'Fila 1',
        'Fila 2',
        'Fila 3',
        'Fila 4',
      ],
    );
  }

  static void registerWidgetActionListener(Function(String action) onAction) {
    const methodChannel = MethodChannel('com.example.music_music/widget_actions');
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final action = call.arguments as String;
        onAction(action);
      }
    });
  }

}
