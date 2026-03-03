import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

abstract class EqualizerBackend {
  void attachPlayer(AudioPlayer player);

  Future<void> apply({
    required bool enabled,
    required double preampDb,
    required Map<int, double> bandGainsDb,
  });

  Future<void> dispose();
}

EqualizerBackend createPlatformEqualizerBackend() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidEqualizerBackend();
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
  }) {
    if (_disposed) return Future<void>.value();
    _applyChain = _applyChain
        .then(
          (_) => _applyInternal(
            enabled: enabled,
            preampDb: preampDb,
            bandGainsDb: bandGainsDb,
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
