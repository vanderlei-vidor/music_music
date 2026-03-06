import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:music_music/core/music/music_scanner_factory.dart'
    if (dart.library.html) 'package:music_music/core/music/music_scanner_factory_web.dart';
import 'package:music_music/core/utils/podcast_detector.dart';
import 'package:music_music/data/local/database_helper.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/data/models/search_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeViewModel extends ChangeNotifier {
  static const _lastAutoSyncAtKey = 'library_last_auto_sync_at';
  static const _backgroundSyncInterval = Duration(hours: 6);

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final List<MusicEntity> _musics = [];
  int _musicsVersion = 0;
  List<AlbumGroup>? _albumGroupsCache;
  int _albumGroupsCacheVersion = -1;
  Map<String, List<MusicEntity>>? _artistsCache;
  int _artistsCacheVersion = -1;

  bool _isLoading = true;
  bool _isScanning = false;
  bool _hasHydratedLibrary = false;
  bool _permissionDenied = false;
  bool _didAutoScan = false;

  bool _showScanSuccess = false;
  bool _showMiniPlayerGlow = false;
  DateTime? _lastSyncAt;
  String? _lastSyncError;
  LibrarySyncResult? _lastSyncResult;

  List<MusicEntity> get musics => _musics;
  List<AlbumGroup> get albumGroups {
    if (_albumGroupsCacheVersion == _musicsVersion &&
        _albumGroupsCache != null) {
      return _albumGroupsCache!;
    }
    final grouped = <String, List<MusicEntity>>{};
    for (final m in _musics) {
      final album = (m.album == null || m.album!.isEmpty)
          ? 'Desconhecido'
          : m.album!;
      final artist = m.artist.isNotEmpty ? m.artist : 'Desconhecido';
      final key = '$album||$artist';
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final groups = grouped.entries.map((entry) {
      final parts = entry.key.split('||');
      return AlbumGroup(
        album: parts.first,
        artist: parts.length > 1 ? parts[1] : 'Desconhecido',
        musics: entry.value,
      );
    }).toList();
    _albumGroupsCache = groups;
    _albumGroupsCacheVersion = _musicsVersion;
    return groups;
  }

  Map<String, List<MusicEntity>> get artistsGrouped {
    if (_artistsCacheVersion == _musicsVersion && _artistsCache != null) {
      return _artistsCache!;
    }
    final artists = <String, List<MusicEntity>>{};
    for (final m in _musics) {
      final name = m.artist.isNotEmpty ? m.artist : 'Desconhecido';
      artists.putIfAbsent(name, () => []).add(m);
    }
    _artistsCache = artists;
    _artistsCacheVersion = _musicsVersion;
    return artists;
  }

  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  bool get hasHydratedLibrary => _hasHydratedLibrary;
  bool get permissionDenied => _permissionDenied;
  bool get showScanSuccess => _showScanSuccess;
  bool get showMiniPlayerGlow => _showMiniPlayerGlow;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastSyncError => _lastSyncError;
  LibrarySyncResult? get lastSyncResult => _lastSyncResult;
  String get lastSyncSummary {
    final result = _lastSyncResult;
    if (result == null) return 'Biblioteca sincronizada.';

    if (result.changed == 0) {
      return 'Biblioteca ja estava atualizada.';
    }

    return 'Sync concluido: +${result.added} novas, '
        '${result.restored} restauradas, '
        '${result.updated} atualizadas, '
        '${result.removed} removidas.';
  }

  Timer? _searchDebounce;
  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  final List<MusicEntity> _visibleMusics = [];
  final List<MusicEntity> _podcastMusics = [];

  List<MusicEntity> get visibleMusics => _visibleMusics;
  List<MusicEntity> get podcastMusics => _podcastMusics;

  final List<SearchResult> _searchResults = [];
  List<SearchResult> get searchResults => _searchResults;

  HomeViewModel() {
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await loadMusics();

    if (kIsWeb) return;

    if (_musics.isEmpty) {
      await _runScan(
        force: true,
        showSuccess: true,
        setPermissionDeniedOnEmpty: true,
      );
      return;
    }

    final shouldSync = await _shouldRunBackgroundSync();
    if (!shouldSync) return;

    // Fast startup: show DB data immediately and sync in background.
    unawaited(
      _runScan(
        force: true,
        showSuccess: false,
        setPermissionDeniedOnEmpty: false,
      ),
    );
  }

  Future<void> autoScan() async {
    await _runScan(
      force: false,
      showSuccess: false,
      setPermissionDeniedOnEmpty: _musics.isEmpty,
    );
  }

  Future<void> manualRescan() async {
    await _runScan(
      force: true,
      showSuccess: true,
      setPermissionDeniedOnEmpty: _musics.isEmpty,
    );
  }

  Future<void> _runScan({
    required bool force,
    required bool showSuccess,
    required bool setPermissionDeniedOnEmpty,
  }) async {
    if (kIsWeb || _isScanning) return;
    if (!force && _didAutoScan) return;

    _didAutoScan = true;
    _isScanning = true;
    _permissionDenied = false;
    _lastSyncError = null;
    notifyListeners();

    try {
      final scanner = getMusicScanner();
      final rawList = await scanner.scan();

      if (rawList.isEmpty) {
        if (setPermissionDeniedOnEmpty) {
          _permissionDenied = _shouldTreatEmptyScanAsPermissionDenied();
        }
        _lastSyncAt = DateTime.now();
        await _saveLastAutoSyncAt(_lastSyncAt!);
        return;
      }

      final processed = await compute(processScanIsolate, rawList);
      _lastSyncResult = await _dbHelper.syncMusicsFromScan(processed);
      await loadMusics(showLoading: false);

      _lastSyncAt = DateTime.now();
      await _saveLastAutoSyncAt(_lastSyncAt!);
      if (showSuccess) {
        _showScanSuccess = true;
        triggerMiniPlayerGlow();
      }
    } catch (e) {
      _lastSyncError = e.toString();
      debugPrint('Erro ao sincronizar biblioteca: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> loadMusics({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final result = (await _dbHelper.getAllMusicsV2())
          .map(PodcastDetector.normalizeGenre)
          .map(PodcastDetector.normalizeMediaType)
          .toList();

      _musics
        ..clear()
        ..addAll(result);

      _visibleMusics
        ..clear()
        ..addAll(_musics.where((m) => !PodcastDetector.isPodcast(m)));

      _podcastMusics
        ..clear()
        ..addAll(_musics.where(PodcastDetector.isPodcast));

      _musicsVersion++;
      _albumGroupsCacheVersion = -1;
      _artistsCacheVersion = -1;
    } catch (e) {
      debugPrint('Erro ao carregar musicas: $e');
    } finally {
      _isLoading = false;
      _hasHydratedLibrary = true;
      notifyListeners();
    }
  }

  void consumeScanSuccess() {
    _showScanSuccess = false;
  }

  void triggerMiniPlayerGlow() {
    _showMiniPlayerGlow = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 4), () {
      _showMiniPlayerGlow = false;
      notifyListeners();
    });
  }

  Future<void> insertWebMusic(MusicEntity music) async {
    final normalized = PodcastDetector.normalizeMediaType(
      PodcastDetector.normalizeGenre(music),
    );
    await _dbHelper.insertMusicV2(normalized);
    await loadMusics();
  }

  Future<void> setManualMediaType(
    MusicEntity music, {
    required bool isPodcast,
  }) async {
    final target = isPodcast
        ? PodcastDetector.mediaTypePodcast
        : PodcastDetector.mediaTypeMusic;
    await _dbHelper.updateMediaType(music.audioUrl, target);
    await loadMusics();
  }

  Future<void> removeMusicFromLibrary(MusicEntity music) async {
    await _dbHelper.deleteMusicByAudioUrl(music.audioUrl);
    await loadMusics();
  }

  Future<List<MusicEntity>> getRemovedMusics() async {
    return (await _dbHelper.getDeletedMusicsV2())
        .map(PodcastDetector.normalizeGenre)
        .map(PodcastDetector.normalizeMediaType)
        .toList();
  }

  Future<void> restoreMusicToLibrary(MusicEntity music) async {
    await _dbHelper.restoreMusicByAudioUrl(music.audioUrl);
    await loadMusics();
  }

  Future<void> permanentlyDeleteFromTrash(MusicEntity music) async {
    await _dbHelper.permanentlyDeleteMusicByAudioUrl(music.audioUrl);
  }

  Future<int> permanentlyDeleteAllFromTrash() async {
    return _dbHelper.permanentlyDeleteAllDeletedMusics();
  }

  void searchMusics(String query) {
    _currentQuery = query;
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchResults.clear();

      if (query.isEmpty) {
        notifyListeners();
        return;
      }

      final q = query.toLowerCase();

      final matches = _musics.where((m) {
        return m.title.toLowerCase().contains(q) ||
            m.artist.toLowerCase().contains(q) ||
            (m.album ?? '').toLowerCase().contains(q);
      }).toList();

      matches.sort(
        (a, b) => _calculateSearchScore(b, q) - _calculateSearchScore(a, q),
      );

      for (final m in matches) {
        _searchResults.add(
          SearchResult(type: SearchType.music, title: m.title, music: m),
        );
      }

      final artists = _musics
          .map((m) => m.artist)
          .toSet()
          .where((a) => a.toLowerCase().contains(q));

      for (final a in artists) {
        _searchResults.add(SearchResult(type: SearchType.artist, title: a));
      }

      final albums = _musics
          .map((m) => m.album ?? '')
          .toSet()
          .where((a) => a.isNotEmpty && a.toLowerCase().contains(q));

      for (final a in albums) {
        _searchResults.add(SearchResult(type: SearchType.album, title: a));
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  bool _shouldTreatEmptyScanAsPermissionDenied() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  Future<bool> _shouldRunBackgroundSync() async {
    final last = await _loadLastAutoSyncAt();
    if (last == null) return true;
    return DateTime.now().difference(last) >= _backgroundSyncInterval;
  }

  Future<DateTime?> _loadLastAutoSyncAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_lastAutoSyncAtKey);
      if (value == null || value <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLastAutoSyncAt(DateTime when) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastAutoSyncAtKey, when.millisecondsSinceEpoch);
    } catch (_) {
      // Best-effort persistence.
    }
  }
}

List<MusicEntity> processScanIsolate(List<MusicEntity> musics) {
  return musics
      .where((m) => m.audioUrl.isNotEmpty)
      .map(PodcastDetector.normalizeGenre)
      .map(PodcastDetector.normalizeMediaType)
      .toList();
}

class AlbumGroup {
  final String album;
  final String artist;
  final List<MusicEntity> musics;

  const AlbumGroup({
    required this.album,
    required this.artist,
    required this.musics,
  });
}

int _calculateSearchScore(MusicEntity m, String q) {
  var score = 0;

  final title = m.title.toLowerCase();
  final artist = m.artist.toLowerCase();
  final album = (m.album ?? '').toLowerCase();

  if (title.startsWith(q)) score += 100;
  if (artist.startsWith(q)) score += 80;
  if (album.startsWith(q)) score += 60;

  if (title.contains(q)) score += 50;
  if (artist.contains(q)) score += 30;
  if (album.contains(q)) score += 20;

  return score;
}
