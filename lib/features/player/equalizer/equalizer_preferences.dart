import 'dart:convert';

import 'package:music_music/features/player/equalizer/equalizer_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EqualizerPreferences {
  static const String _stateKey = 'equalizer_state_v1';
  static const String _profileStateKeyPrefix = 'equalizer_state_profile_v1_';
  static const String _activeProfileKey = 'equalizer_active_profile_v1';
  static const String _userPresetsKey = 'equalizer_user_presets_v1';
  static const String _selectedPresetIdKey = 'equalizer_selected_user_preset_v1';

  Future<Map<String, dynamic>?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveState(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, jsonEncode(state));
  }

  Future<Map<String, dynamic>?> loadProfileState(String profileKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_profileStateKeyPrefix$profileKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfileState(
    String profileKey,
    Map<String, dynamic> state,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_profileStateKeyPrefix$profileKey',
      jsonEncode(state),
    );
  }

  Future<String?> loadActiveProfileKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProfileKey);
  }

  Future<void> saveActiveProfileKey(String profileKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProfileKey, profileKey);
  }

  Future<List<EqualizerUserPreset>> loadUserPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userPresetsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => EqualizerUserPreset.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveUserPresets(List<EqualizerUserPreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = presets.map((p) => p.toMap()).toList();
    await prefs.setString(_userPresetsKey, jsonEncode(payload));
  }

  Future<String?> loadSelectedPresetId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_selectedPresetIdKey);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> saveSelectedPresetId(String? presetId) async {
    final prefs = await SharedPreferences.getInstance();
    if (presetId == null || presetId.isEmpty) {
      await prefs.remove(_selectedPresetIdKey);
      return;
    }
    await prefs.setString(_selectedPresetIdKey, presetId);
  }
}
