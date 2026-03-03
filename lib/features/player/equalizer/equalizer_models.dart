enum EqualizerPreset {
  flat,
  bassBoost,
  vocalBoost,
  trebleBoost,
  acoustic,
  party,
  custom,
}

class EqualizerBand {
  final int frequencyHz;
  final String label;
  final double minDb;
  final double maxDb;

  const EqualizerBand({
    required this.frequencyHz,
    required this.label,
    this.minDb = -12.0,
    this.maxDb = 12.0,
  });
}

class EqualizerConfig {
  static const List<EqualizerBand> defaultBands = [
    EqualizerBand(frequencyHz: 31, label: '31 Hz'),
    EqualizerBand(frequencyHz: 62, label: '62 Hz'),
    EqualizerBand(frequencyHz: 125, label: '125 Hz'),
    EqualizerBand(frequencyHz: 250, label: '250 Hz'),
    EqualizerBand(frequencyHz: 500, label: '500 Hz'),
    EqualizerBand(frequencyHz: 1000, label: '1 kHz'),
    EqualizerBand(frequencyHz: 2000, label: '2 kHz'),
    EqualizerBand(frequencyHz: 4000, label: '4 kHz'),
    EqualizerBand(frequencyHz: 8000, label: '8 kHz'),
    EqualizerBand(frequencyHz: 16000, label: '16 kHz'),
  ];
}

