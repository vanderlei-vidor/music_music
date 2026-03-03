import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_music/features/player/equalizer/equalizer_backend.dart';
import 'package:music_music/features/player/equalizer/equalizer_models.dart';
import 'package:music_music/features/player/equalizer/equalizer_preferences.dart';

class EqualizerViewModel extends ChangeNotifier {
  final EqualizerBackend _backend;
  final EqualizerPreferences _preferences;
  final List<EqualizerBand> _bands;

  bool _enabled = false;
  double _preampDb = 0.0;
  EqualizerPreset _preset = EqualizerPreset.flat;
  bool _autoHeadroomEnabled = true;
  bool _autoGenrePresetEnabled = false;
  String? _lastSyncedGenreKey;
  String? _lastDetectedGenreLabel;
  EqualizerPreset? _lastAutoAppliedPreset;
  late final Map<int, double> _bandGainsDb;
  bool _initialized = false;
  Timer? _persistDebounce;
  Duration _lastApplyDuration = Duration.zero;
  DateTime? _lastApplyAt;
  int _applyCount = 0;
  int _applyErrorCount = 0;

  EqualizerViewModel({
    EqualizerBackend? backend,
    EqualizerPreferences? preferences,
    List<EqualizerBand>? bands,
  }) : _backend = backend ?? NoopEqualizerBackend(),
       _preferences = preferences ?? EqualizerPreferences(),
       _bands = bands ?? EqualizerConfig.defaultBands {
    _bandGainsDb = {for (final band in _bands) band.frequencyHz: 0.0};
    unawaited(_init());
  }

  List<EqualizerBand> get bands => List.unmodifiable(_bands);
  bool get enabled => _enabled;
  double get preampDb => _preampDb;
  EqualizerPreset get preset => _preset;
  bool get initialized => _initialized;
  Map<int, double> get bandGainsDb => Map.unmodifiable(_bandGainsDb);
  bool get autoHeadroomEnabled => _autoHeadroomEnabled;
  bool get autoGenrePresetEnabled => _autoGenrePresetEnabled;
  Duration get lastApplyDuration => _lastApplyDuration;
  DateTime? get lastApplyAt => _lastApplyAt;
  int get applyCount => _applyCount;
  int get applyErrorCount => _applyErrorCount;
  String? get lastDetectedGenreLabel => _lastDetectedGenreLabel;
  EqualizerPreset? get lastAutoAppliedPreset => _lastAutoAppliedPreset;
  double get maxBandBoostDb => _bandGainsDb.values.fold<double>(
    0.0,
    (maxValue, value) => value > maxValue ? value : maxValue,
  );
  double get recommendedSafePreampDb => -maxBandBoostDb;
  double get effectivePreampDb =>
      _autoHeadroomEnabled ? min(_preampDb, recommendedSafePreampDb) : _preampDb;

  double gainFor(int frequencyHz) => _bandGainsDb[frequencyHz] ?? 0.0;

  void attachPlayer(AudioPlayer player) {
    _backend.attachPlayer(player);
    unawaited(_applyToBackend());
  }

  Future<void> _init() async {
    final state = await _preferences.loadState();
    if (state != null) {
      _enabled = state['enabled'] == true;
      _preampDb = _toDouble(state['preampDb']) ?? 0.0;
      _autoHeadroomEnabled = state['autoHeadroomEnabled'] != false;
      _autoGenrePresetEnabled = state['autoGenrePresetEnabled'] == true;

      final presetRaw = state['preset']?.toString() ?? EqualizerPreset.flat.name;
      _preset = EqualizerPreset.values.firstWhere(
        (p) => p.name == presetRaw,
        orElse: () => EqualizerPreset.flat,
      );

      final gainsRaw = state['bandGainsDb'];
      if (gainsRaw is Map) {
        for (final band in _bands) {
          final key = band.frequencyHz.toString();
          _bandGainsDb[band.frequencyHz] = _clampDb(
            _toDouble(gainsRaw[key]) ?? 0.0,
            band,
          );
        }
      }
    }

    _initialized = true;
    notifyListeners();
    await _applyToBackend();
  }

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    _schedulePersistAndApply();
  }

  void setPreampDb(double value, {bool commit = true}) {
    final next = value.clamp(-12.0, 12.0).toDouble();
    if ((_preampDb - next).abs() < 0.001) return;
    _preampDb = next;
    notifyListeners();
    if (commit) {
      _schedulePersistAndApply();
    } else {
      unawaited(_applyToBackend());
    }
  }

  void setAutoHeadroomEnabled(bool value) {
    if (_autoHeadroomEnabled == value) return;
    _autoHeadroomEnabled = value;
    notifyListeners();
    _schedulePersistAndApply();
  }

  void setAutoGenrePresetEnabled(bool value) {
    if (_autoGenrePresetEnabled == value) return;
    _autoGenrePresetEnabled = value;
    if (!value) {
      _lastSyncedGenreKey = null;
      _lastDetectedGenreLabel = null;
      _lastAutoAppliedPreset = null;
    }
    notifyListeners();
    _schedulePersistAndApply();
  }

  void lockCurrentPreset() {
    if (!_autoGenrePresetEnabled) return;
    _autoGenrePresetEnabled = false;
    _lastSyncedGenreKey = null;
    notifyListeners();
    _schedulePersistAndApply();
  }

  void syncGenre(String? genre) {
    if (!_autoGenrePresetEnabled) return;
    final key = _normalizeGenreKey(genre);
    if (key == null || key == _lastSyncedGenreKey) return;

    final mapped = _presetForGenre(key);
    _lastSyncedGenreKey = key;
    _lastDetectedGenreLabel = genre?.trim();
    _lastAutoAppliedPreset = mapped;
    if (mapped == null || mapped == _preset) {
      notifyListeners();
      return;
    }
    applyPreset(mapped);
  }

  void setBandGainDb(int frequencyHz, double value, {bool commit = true}) {
    final band = _bands.firstWhere(
      (b) => b.frequencyHz == frequencyHz,
      orElse: () => const EqualizerBand(frequencyHz: 0, label: ''),
    );
    if (band.frequencyHz == 0) return;

    final next = _clampDb(value, band);
    final current = _bandGainsDb[frequencyHz] ?? 0.0;
    if ((current - next).abs() < 0.001) return;

    _bandGainsDb[frequencyHz] = next;
    _preset = EqualizerPreset.custom;
    notifyListeners();

    if (commit) {
      _schedulePersistAndApply();
    } else {
      unawaited(_applyToBackend());
    }
  }

  void applyPreset(EqualizerPreset preset) {
    if (preset == EqualizerPreset.custom) return;
    final values = _presetValues(preset);
    for (var i = 0; i < _bands.length; i++) {
      _bandGainsDb[_bands[i].frequencyHz] = values[i];
    }
    _preset = preset;
    notifyListeners();
    _schedulePersistAndApply();
  }

  void reset() {
    for (final band in _bands) {
      _bandGainsDb[band.frequencyHz] = 0.0;
    }
    _preampDb = 0.0;
    _preset = EqualizerPreset.flat;
    _lastSyncedGenreKey = null;
    _lastDetectedGenreLabel = null;
    _lastAutoAppliedPreset = null;
    notifyListeners();
    _schedulePersistAndApply();
  }

  Future<void> _applyToBackend() async {
    final sw = Stopwatch()..start();
    try {
      await _backend.apply(
        enabled: _enabled,
        preampDb: effectivePreampDb,
        bandGainsDb: _bandGainsDb,
      );
      _applyCount += 1;
    } catch (_) {
      _applyErrorCount += 1;
      rethrow;
    } finally {
      sw.stop();
      _lastApplyDuration = sw.elapsed;
      _lastApplyAt = DateTime.now();
      notifyListeners();
    }
  }

  void _schedulePersistAndApply() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 180), () async {
      await _persist();
      await _applyToBackend();
    });
  }

  Future<void> _persist() async {
    final payload = {
      'enabled': _enabled,
      'preampDb': _preampDb,
      'autoHeadroomEnabled': _autoHeadroomEnabled,
      'autoGenrePresetEnabled': _autoGenrePresetEnabled,
      'preset': _preset.name,
      'bandGainsDb': {
        for (final entry in _bandGainsDb.entries)
          entry.key.toString(): entry.value,
      },
    };
    await _preferences.saveState(payload);
  }

  List<double> _presetValues(EqualizerPreset preset) {
    switch (preset) {
      case EqualizerPreset.flat:
        return const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      case EqualizerPreset.bassBoost:
        return const [6, 5, 4, 2, 1, 0, -1, -2, -3, -4];
      case EqualizerPreset.vocalBoost:
        return const [-2, -1, 1, 3, 5, 6, 5, 3, 1, 0];
      case EqualizerPreset.trebleBoost:
        return const [-4, -3, -2, -1, 0, 1, 3, 5, 6, 6];
      case EqualizerPreset.acoustic:
        return const [2, 1, 0, -1, 1, 3, 4, 3, 2, 1];
      case EqualizerPreset.party:
        return const [5, 4, 2, 0, -1, 1, 3, 5, 4, 3];
      case EqualizerPreset.custom:
        return List<double>.filled(_bands.length, 0.0);
    }
  }

  double _clampDb(double value, EqualizerBand band) =>
      value.clamp(band.minDb, band.maxDb).toDouble();

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String? _normalizeGenreKey(String? genre) {
    final normalized = _stripDiacritics(genre?.trim().toLowerCase() ?? '');
    if (normalized.isEmpty) return null;
    return normalized;
  }

  EqualizerPreset? _presetForGenre(String genreKey) {
    final tokens = genreKey
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toSet();
    final allText = ' $genreKey ';

    if (_containsAnyToken(tokens, const [
          'classica',
          'classical',
          'orquestra',
          'orchestra',
          'symphony',
          'instrumental',
          'acoustic',
          'acustico',
          'acustica',
          'piano',
        ]) ||
        allText.contains('classic')) {
      return EqualizerPreset.acoustic;
    }

    if (_containsAnyToken(tokens, const [
      'rock',
      'metal',
      'eletronica',
      'electronic',
      'edm',
      'dance',
      'house',
      'techno',
      'trance',
      'dubstep',
      'hiphop',
      'hip',
      'hop',
      'rap',
      'trap',
      'drum',
      'bass',
      'dnb',
    ])) {
      return EqualizerPreset.party;
    }

    if (_containsAnyToken(tokens, const [
      'jazz',
      'vocal',
      'podcast',
      'audiobook',
      'speech',
      'mpb',
      'bossanova',
      'bossa',
      'nova',
      'blues',
      'samba',
      'choro',
      'folk',
      'gospel',
      'louvor',
      'worship',
    ])) {
      return EqualizerPreset.vocalBoost;
    }

    if (_containsAnyToken(tokens, const [
      'pop',
      'funk',
      'reggaeton',
      'reggaeton',
      'sertanejo',
      'arrocha',
      'forro',
      'piseiro',
      'pagode',
      'axe',
      'latin',
      'latino',
    ])) {
      return EqualizerPreset.bassBoost;
    }

    return null;
  }

  bool _containsAnyToken(Set<String> tokens, List<String> candidates) {
    for (final candidate in candidates) {
      if (tokens.contains(candidate)) return true;
    }
    return false;
  }

  String _stripDiacritics(String value) {
    const map = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(map[char] ?? char);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    unawaited(_backend.dispose());
    super.dispose();
  }
}
