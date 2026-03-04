import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
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
  EqualizerOutputProfile _activeProfile = EqualizerOutputProfile.headphones;
  bool _autoHeadroomEnabled = true;
  bool _autoGenrePresetEnabled = false;
  List<EqualizerUserPreset> _userPresets = const [];
  String? _selectedUserPresetId;
  String? _lastSyncedGenreKey;
  String? _lastDetectedGenreLabel;
  EqualizerPreset? _lastAutoAppliedPreset;
  late final Map<int, double> _bandGainsDb;
  bool _initialized = false;
  Timer? _persistDebounce;
  StreamSubscription<Set<AudioDevice>>? _audioDevicesSub;
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
  EqualizerOutputProfile get activeProfile => _activeProfile;
  List<EqualizerOutputProfile> get availableProfiles =>
      EqualizerOutputProfile.values;
  List<EqualizerUserPreset> get userPresets => List.unmodifiable(_userPresets);
  String? get selectedUserPresetId => _selectedUserPresetId;
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
    final activeProfileKey = await _preferences.loadActiveProfileKey();
    _activeProfile = EqualizerOutputProfile.values.firstWhere(
      (p) => p.storageKey == activeProfileKey,
      orElse: () => EqualizerOutputProfile.headphones,
    );
    final state =
        await _preferences.loadProfileState(_activeProfile.storageKey) ??
        await _preferences.loadState();
    _userPresets = await _preferences.loadUserPresets();
    _selectedUserPresetId = await _preferences.loadSelectedPresetId();
    if (state != null) _applyStateMap(state);

    await _startAutoProfileSwitching();
    _initialized = true;
    notifyListeners();
    await _applyToBackend();
  }

  Future<void> setActiveProfile(EqualizerOutputProfile profile) async {
    if (_activeProfile == profile) return;

    await _persist();
    _activeProfile = profile;
    await _preferences.saveActiveProfileKey(profile.storageKey);

    final profileState = await _preferences.loadProfileState(profile.storageKey);
    if (profileState != null) {
      _applyStateMap(profileState);
    } else {
      _enabled = false;
      _preampDb = 0.0;
      _preset = EqualizerPreset.flat;
      _autoHeadroomEnabled = true;
      _autoGenrePresetEnabled = false;
      _selectedUserPresetId = null;
      for (final band in _bands) {
        _bandGainsDb[band.frequencyHz] = 0.0;
      }
    }

    _lastSyncedGenreKey = null;
    _lastDetectedGenreLabel = null;
    _lastAutoAppliedPreset = null;
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
    _selectedUserPresetId = null;
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
    _selectedUserPresetId = null;
    notifyListeners();
    _schedulePersistAndApply();
  }

  Future<bool> saveCurrentAsPreset(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length > 24) return false;
    final duplicate = _userPresets.any(
      (p) => p.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) return false;

    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final preset = EqualizerUserPreset(
      id: id,
      name: trimmed,
      preampDb: _preampDb,
      bandGainsDb: Map<int, double>.from(_bandGainsDb),
      createdAt: now,
      updatedAt: now,
    );
    _userPresets = [..._userPresets, preset];
    _selectedUserPresetId = id;
    _preset = EqualizerPreset.custom;
    notifyListeners();
    await _preferences.saveUserPresets(_userPresets);
    await _preferences.saveSelectedPresetId(_selectedUserPresetId);
    return true;
  }

  Future<bool> applyUserPreset(String presetId) async {
    final preset = _userPresets.where((p) => p.id == presetId).firstOrNull;
    if (preset == null) return false;

    _preampDb = preset.preampDb.clamp(-12.0, 12.0).toDouble();
    for (final band in _bands) {
      final raw = preset.bandGainsDb[band.frequencyHz] ?? 0.0;
      _bandGainsDb[band.frequencyHz] = _clampDb(raw, band);
    }
    _selectedUserPresetId = preset.id;
    _preset = EqualizerPreset.custom;
    notifyListeners();
    _schedulePersistAndApply();
    await _preferences.saveSelectedPresetId(_selectedUserPresetId);
    return true;
  }

  Future<bool> renameUserPreset(String presetId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed.length > 24) return false;
    final duplicate = _userPresets.any(
      (p) => p.id != presetId && p.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) return false;

    var changed = false;
    _userPresets = _userPresets.map((p) {
      if (p.id != presetId) return p;
      changed = true;
      return p.copyWith(name: trimmed, updatedAt: DateTime.now());
    }).toList();
    if (!changed) return false;
    notifyListeners();
    await _preferences.saveUserPresets(_userPresets);
    return true;
  }

  Future<bool> deleteUserPreset(String presetId) async {
    final lengthBefore = _userPresets.length;
    _userPresets = _userPresets.where((p) => p.id != presetId).toList();
    if (_userPresets.length == lengthBefore) return false;
    if (_selectedUserPresetId == presetId) {
      _selectedUserPresetId = null;
      await _preferences.saveSelectedPresetId(null);
    }
    notifyListeners();
    await _preferences.saveUserPresets(_userPresets);
    return true;
  }

  String exportUserPresetsJson() {
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'presets': _userPresets.map((p) => p.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<int> importUserPresetsJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('JSON inválido.');
    }

    final rawPresets = decoded['presets'];
    if (rawPresets is! List) {
      throw const FormatException('Campo "presets" ausente ou inválido.');
    }

    final existingByName = <String, EqualizerUserPreset>{
      for (final p in _userPresets) p.name.toLowerCase(): p,
    };
    var importedCount = 0;
    final next = List<EqualizerUserPreset>.from(_userPresets);

    for (final item in rawPresets) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final imported = EqualizerUserPreset.fromMap(map);
      final cleanName = imported.name.trim();
      if (cleanName.isEmpty) continue;
      final normalized = cleanName.toLowerCase();
      if (existingByName.containsKey(normalized)) continue;

      final clampedBands = <int, double>{};
      for (final band in _bands) {
        final raw = imported.bandGainsDb[band.frequencyHz] ?? 0.0;
        clampedBands[band.frequencyHz] = _clampDb(raw, band);
      }

      next.add(
        EqualizerUserPreset(
          id: '${DateTime.now().microsecondsSinceEpoch}-${next.length}',
          name: cleanName,
          preampDb: imported.preampDb.clamp(-12.0, 12.0).toDouble(),
          bandGainsDb: clampedBands,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      existingByName[normalized] = next.last;
      importedCount += 1;
    }

    if (importedCount == 0) return 0;
    _userPresets = next;
    notifyListeners();
    await _preferences.saveUserPresets(_userPresets);
    return importedCount;
  }

  void reset() {
    for (final band in _bands) {
      _bandGainsDb[band.frequencyHz] = 0.0;
    }
    _preampDb = 0.0;
    _preset = EqualizerPreset.flat;
    _selectedUserPresetId = null;
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
    final payload = _stateFromCurrent();
    await _preferences.saveState(payload);
    await _preferences.saveProfileState(_activeProfile.storageKey, payload);
    await _preferences.saveActiveProfileKey(_activeProfile.storageKey);
    await _preferences.saveSelectedPresetId(_selectedUserPresetId);
  }

  Map<String, dynamic> _stateFromCurrent() {
    return {
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
  }

  void _applyStateMap(Map<String, dynamic> state) {
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
    for (final band in _bands) {
      final key = band.frequencyHz.toString();
      _bandGainsDb[band.frequencyHz] = _clampDb(
        gainsRaw is Map ? _toDouble(gainsRaw[key]) ?? 0.0 : 0.0,
        band,
      );
    }
  }

  Future<void> _startAutoProfileSwitching() async {
    try {
      final session = await AudioSession.instance;
      final devices = await session.getDevices();
      await _syncProfileWithDevices(devices);
      await _audioDevicesSub?.cancel();
      _audioDevicesSub = session.devicesStream.listen((devices) {
        unawaited(_syncProfileWithDevices(devices));
      });
    } catch (_) {
      // Platform may not support device route reporting. Ignore silently.
    }
  }

  Future<void> _syncProfileWithDevices(Set<AudioDevice> devices) async {
    final next = _profileFromDevices(devices);
    if (next == null || next == _activeProfile) return;
    await setActiveProfile(next);
  }

  EqualizerOutputProfile? _profileFromDevices(Set<AudioDevice> devices) {
    final outputs = devices.where((d) => d.isOutput).toList();
    if (outputs.isEmpty) return null;

    final hasCar = outputs.any((d) => d.type == AudioDeviceType.carAudio);
    if (hasCar) return EqualizerOutputProfile.car;

    final hasBluetooth = outputs.any(
      (d) =>
          d.type == AudioDeviceType.bluetoothA2dp ||
          d.type == AudioDeviceType.bluetoothSco ||
          d.type == AudioDeviceType.bluetoothLe ||
          d.type == AudioDeviceType.hearingAid,
    );
    if (hasBluetooth) return EqualizerOutputProfile.bluetooth;

    final hasHeadphones = outputs.any(
      (d) =>
          d.type == AudioDeviceType.wiredHeadphones ||
          d.type == AudioDeviceType.wiredHeadset ||
          d.type == AudioDeviceType.headsetMic ||
          d.type == AudioDeviceType.usbAudio,
    );
    if (hasHeadphones) return EqualizerOutputProfile.headphones;

    return null;
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
    _audioDevicesSub?.cancel();
    unawaited(_backend.dispose());
    super.dispose();
  }
}
