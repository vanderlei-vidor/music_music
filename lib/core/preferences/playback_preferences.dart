import 'package:shared_preferences/shared_preferences.dart';

/// Configurações de Gapless Playback e Crossfade
class PlaybackPreferences {
  static const String _gaplessKey = 'playback_gapless_enabled';
  static const String _crossfadeKey = 'playback_crossfade_seconds';
  static const String _crossfadeEnabledKey = 'playback_crossfade_enabled';

  /// Gapless habilitado por padrão (sem silêncio entre faixas)
  static const bool defaultGapless = true;
  
  /// Crossfade desabilitado por padrão (0 segundos)
  static const int defaultCrossfadeSeconds = 0;
  
  /// Valor máximo de crossfade permitido
  static const int maxCrossfadeSeconds = 12;

  /// Habilita/desabilita playback gapless
  Future<void> setGaplessEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gaplessKey, enabled);
  }

  /// Verifica se gapless está habilitado
  Future<bool> isGaplessEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gaplessKey) ?? defaultGapless;
  }

  /// Habilita/desabilita crossfade
  Future<void> setCrossfadeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crossfadeEnabledKey, enabled);
  }

  /// Verifica se crossfade está habilitado
  Future<bool> isCrossfadeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_crossfadeEnabledKey) ?? false;
  }

  /// Define duração do crossfade em segundos
  Future<void> setCrossfadeSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = seconds.clamp(0, maxCrossfadeSeconds);
    await prefs.setInt(_crossfadeKey, clamped);
  }

  /// Obtém duração do crossfade em segundos
  Future<int> getCrossfadeSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_crossfadeKey) ?? defaultCrossfadeSeconds;
  }

  /// Carrega todas as configurações de uma vez
  Future<PlaybackConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return PlaybackConfig(
      gaplessEnabled: prefs.getBool(_gaplessKey) ?? defaultGapless,
      crossfadeEnabled: prefs.getBool(_crossfadeEnabledKey) ?? false,
      crossfadeSeconds: prefs.getInt(_crossfadeKey) ?? defaultCrossfadeSeconds,
    );
  }
}

/// Configuração de playback carregada
class PlaybackConfig {
  final bool gaplessEnabled;
  final bool crossfadeEnabled;
  final int crossfadeSeconds;

  const PlaybackConfig({
    required this.gaplessEnabled,
    required this.crossfadeEnabled,
    required this.crossfadeSeconds,
  });

  /// Crossfade está ativo e tem duração > 0
  bool get isCrossfadeActive => crossfadeEnabled && crossfadeSeconds > 0;

  /// Duração do crossfade como Duration
  Duration get crossfadeDuration => Duration(seconds: crossfadeSeconds);

  @override
  bool operator ==(Object other) {
    return other is PlaybackConfig &&
        other.gaplessEnabled == gaplessEnabled &&
        other.crossfadeEnabled == crossfadeEnabled &&
        other.crossfadeSeconds == crossfadeSeconds;
  }

  @override
  int get hashCode => Object.hash(gaplessEnabled, crossfadeEnabled, crossfadeSeconds);
}
