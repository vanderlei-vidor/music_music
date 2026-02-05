import 'package:flutter/material.dart';
import 'package:music_music/data/models/search_result.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/data/local/database_helper.dart';
import 'package:music_music/core/music/music_scanner_factory.dart'
    if (dart.library.html)
        'package:music_music/core/music/music_scanner_factory_web.dart';
import 'package:music_music/core/music/music_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

class HomeViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final List<MusicEntity> _musics = [];

  bool _isLoading = true;
  bool _isScanning = false;
  bool _permissionDenied = false;
  bool _didAutoScan = false;

  bool _showScanSuccess = false;
  bool _showMiniPlayerGlow = false;

  List<MusicEntity> get musics => _musics;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  bool get permissionDenied => _permissionDenied;
  bool get showScanSuccess => _showScanSuccess;
  bool get showMiniPlayerGlow => _showMiniPlayerGlow;
  Timer? _searchDebounce;
  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  final List<MusicEntity> _visibleMusics = [];

  List<MusicEntity> get visibleMusics => _visibleMusics;

  final List<SearchResult> _searchResults = [];
  List<SearchResult> get searchResults => _searchResults;

  HomeViewModel() {
    if (kIsWeb) {
      loadMusics();
    } else {
      autoScan();
    }
  }

  Future<void> autoScan() async {
    if (kIsWeb || _isScanning || _didAutoScan) return;

    _isScanning = true;
    _permissionDenied = false;
    notifyListeners();

    try {
      final scanner = getMusicScanner();
      final rawList = await scanner.scan();

      if (rawList.isEmpty) {
        _permissionDenied = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _didAutoScan = true;

      final processed = await compute(processScanIsolate, rawList);

      for (final music in processed) {
        await _dbHelper.insertMusicIfNotExists(music);
      }

      await loadMusics();

      _showScanSuccess = true;
      triggerMiniPlayerGlow();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> manualRescan() async {
    if (_isScanning) return;

    _isScanning = true;
    _permissionDenied = false;
    notifyListeners();

    try {
      final scanner = getMusicScanner();
      final rawList = await scanner.scan();

      final processed = await compute(processScanIsolate, rawList);

      for (final music in processed) {
        await _dbHelper.insertMusicIfNotExists(music);
      }

      await loadMusics();

      _showScanSuccess = true;
      triggerMiniPlayerGlow();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> loadMusics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _dbHelper.getAllMusicsV2();

      _musics
        ..clear()
        ..addAll(result);

      // 🔥 ISSO É O QUE FALTAVA
      _visibleMusics
        ..clear()
        ..addAll(_musics);
    } catch (e) {
      debugPrint('Erro ao carregar músicas: $e');
    } finally {
      _isLoading = false;
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
    await _dbHelper.insertMusicV2(music);
    await loadMusics();
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

      /// 🎵 MÚSICAS (com ranking)
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

      /// 👤 ARTISTAS
      final artists = _musics
          .map((m) => m.artist)
          .toSet()
          .where((a) => a.toLowerCase().contains(q));

      for (final a in artists) {
        _searchResults.add(SearchResult(type: SearchType.artist, title: a));
      }

      /// 💿 ÁLBUNS
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
}

List<MusicEntity> processScanIsolate(List<MusicEntity> musics) {
  return musics.where((m) => m.audioUrl.isNotEmpty).toList();
}

int _calculateSearchScore(MusicEntity m, String q) {
  int score = 0;

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


