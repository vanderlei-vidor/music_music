import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_music/features/player/equalizer/equalizer_models.dart';

abstract class EqualizerBackend {
  void attachPlayer(AudioPlayer player);

  Future<void> apply({
    required bool enabled,
    required double preampDb,
    required Map<int, double> bandGainsDb,
    required IosEqProcessingMode iosMode,
  });

  Future<void> dispose();
}

EqualizerBackend createPlatformEqualizerBackend() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidEqualizerBackend();
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    return IosEqualizerBackend();
  }
  return NoopEqualizerBackend();
}

AudioPlayer createAudioPlayerForBackend(EqualizerBackend backend) {
  if (backend is AndroidEqualizerBackend) {
    return AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [backend.equalizer, backend.loudnessEnhancer],
      ),
    );
  }
  return AudioPlayer();
}

class NoopEqualizerBackend implements EqualizerBackend {
  @override
  void attachPlayer(AudioPlayer player) {}

  @override
  Future<void> apply({
    required bool enabled,
    required double preampDb,
    required Map<int, double> bandGainsDb,
    required IosEqProcessingMode iosMode,
  }) async {}

  @override
  Future<void> dispose() async {}
}

class AndroidEqualizerBackend implements EqualizerBackend {
  final AndroidEqualizer equalizer;
  final AndroidLoudnessEnhancer loudnessEnhancer;

  AudioPlayer? _player;
  bool _disposed = false;
  Future<void> _applyChain = Future<void>.value();
  final Map<int, int> _bandIndexByFrequency = {};

  AndroidEqualizerBackend({
    AndroidEqualizer? equalizer,
    AndroidLoudnessEnhancer? loudnessEnhancer,
  }) : equalizer = equalizer ?? AndroidEqualizer(),
       loudnessEnhancer = loudnessEnhancer ?? AndroidLoudnessEnhancer();

  @override
  void attachPlayer(AudioPlayer player) {
    _player = player;
  }

  @override
  Future<void> apply({
    required bool enabled,
    required double preampDb,
    required Map<int, double> bandGainsDb,
    required IosEqProcessingMode iosMode,
  }) {
    if (_disposed) return Future<void>.value();
    _applyChain = _applyChain
        .then(
          (_) => _applyInternal(
            enabled: enabled,
            preampDb: preampDb,
            bandGainsDb: bandGainsDb,
            iosMode: iosMode,
          ),
        )
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('[Equalizer] apply error: $error');
          debugPrint(stackTrace.toString());
        });
    return _applyChain;
  }

  Future<void> _applyInternal({
    required bool enabled,
    required double preampDb,
    required Map<int, double> bandGainsDb,
    required IosEqProcessingMode iosMode,
  }) async {
    if (_player == null || _disposed) return;

    await equalizer.setEnabled(enabled);
    await loudnessEnhancer.setEnabled(enabled);
    await loudnessEnhancer.setTargetGain(preampDb.clamp(-12.0, 12.0));

    final params = await equalizer.parameters;
    if (params.bands.isEmpty) return;

    for (final entry in bandGainsDb.entries) {
      final targetFrequency = entry.key;
      final gain = entry.value.clamp(params.minDecibels, params.maxDecibels);
      final bandIndex = _resolveBandIndex(targetFrequency, params);
      await params.bands[bandIndex].setGain(gain.toDouble());
    }
  }

  int _resolveBandIndex(int targetFrequency, AndroidEqualizerParameters params) {
    final cached = _bandIndexByFrequency[targetFrequency];
    if (cached != null && cached >= 0 && cached < params.bands.length) {
      return cached;
    }

    var closestIndex = 0;
    var closestDelta = double.infinity;
    for (var i = 0; i < params.bands.length; i++) {
      final center = params.bands[i].centerFrequency;
      final delta = (center - targetFrequency).abs();
      if (delta < closestDelta) {
        closestDelta = delta;
        closestIndex = i;
      }
    }
    _bandIndexByFrequency[targetFrequency] = closestIndex;
    return closestIndex;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _applyChain;
  }
}

class IosEqualizerBackend implements EqualizerBackend {
  AudioPlayer? _player;
  bool _attached = false;
  bool _disposed = false;
  Future<void> _applyChain = Future<void>.value();

  @override
  void attachPlayer(AudioPlayer player) {
    _player = player;
    _attached = true;
  }

  @override
  Future<void> apply({
    required bool enabled,
    required double preampDb,
    required Map<int, double> bandGainsDb,
    required IosEqProcessingMode iosMode,
  }) {
    if (_disposed || !_attached) return Future<void>.value();
    final player = _player;
    if (player == null) return Future<void>.value();
    _applyChain = _applyChain
        .then(
          (_) {
            final effectiveDb = _effectivePreampForMode(
              preampDb: preampDb,
              bandGainsDb: bandGainsDb,
              mode: iosMode,
            );
            return player.darwinSetEqualizer(
              enabled: enabled,
              preampDb: effectiveDb,
              bandGainsDb: bandGainsDb,
            );
          },
        )
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('[Equalizer][iOS] apply error: $error');
          debugPrint(stackTrace.toString());
        });
    return _applyChain;
  }

  double _effectivePreampForMode({
    required double preampDb,
    required Map<int, double> bandGainsDb,
    required IosEqProcessingMode mode,
  }) {
    switch (mode) {
      case IosEqProcessingMode.preampOnly:
        return preampDb.clamp(-12.0, 12.0).toDouble();
      case IosEqProcessingMode.tonalSynthesis:
        final tonalDb = _synthesizedTonalDb(bandGainsDb);
        return (preampDb + tonalDb).clamp(-12.0, 12.0).toDouble();
      case IosEqProcessingMode.trueMultiband:
        // TODO(iOS): switch to native AVAudioEngine multiband when implemented.
        final tonalDb = _synthesizedTonalDb(bandGainsDb);
        return (preampDb + tonalDb).clamp(-12.0, 12.0).toDouble();
    }
  }

  double _synthesizedTonalDb(Map<int, double> bandGainsDb) {
    double at(int hz) => bandGainsDb[hz] ?? 0.0;

    final low = (at(31) + at(62) + at(125)) / 3.0;
    final mid = (at(250) + at(500) + at(1000) + at(2000)) / 4.0;
    final high = (at(4000) + at(8000) + at(16000)) / 3.0;

    // Weighted synthesis that gives user-perceivable tone shift without
    // over-amplifying output.
    final tonal = (low * 0.22) + (mid * 0.10) + (high * 0.18);
    return tonal.clamp(-4.0, 4.0).toDouble();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _applyChain;
    _player = null;
  }
}
