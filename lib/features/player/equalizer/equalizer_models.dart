enum EqualizerPreset {
  flat,
  bassBoost,
  vocalBoost,
  trebleBoost,
  acoustic,
  party,
  custom,
}

enum EqualizerOutputProfile {
  headphones,
  bluetooth,
  car,
}

extension EqualizerOutputProfileX on EqualizerOutputProfile {
  String get storageKey {
    switch (this) {
      case EqualizerOutputProfile.headphones:
        return 'headphones';
      case EqualizerOutputProfile.bluetooth:
        return 'bluetooth';
      case EqualizerOutputProfile.car:
        return 'car';
    }
  }

  String get label {
    switch (this) {
      case EqualizerOutputProfile.headphones:
        return 'Fone';
      case EqualizerOutputProfile.bluetooth:
        return 'Bluetooth';
      case EqualizerOutputProfile.car:
        return 'Carro';
    }
  }
}

class EqualizerUserPreset {
  final String id;
  final String name;
  final double preampDb;
  final Map<int, double> bandGainsDb;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EqualizerUserPreset({
    required this.id,
    required this.name,
    required this.preampDb,
    required this.bandGainsDb,
    required this.createdAt,
    required this.updatedAt,
  });

  EqualizerUserPreset copyWith({
    String? name,
    double? preampDb,
    Map<int, double>? bandGainsDb,
    DateTime? updatedAt,
  }) {
    return EqualizerUserPreset(
      id: id,
      name: name ?? this.name,
      preampDb: preampDb ?? this.preampDb,
      bandGainsDb: bandGainsDb ?? this.bandGainsDb,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'preampDb': preampDb,
      'bandGainsDb': {
        for (final e in bandGainsDb.entries) e.key.toString(): e.value,
      },
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory EqualizerUserPreset.fromMap(Map<String, dynamic> map) {
    final rawBands = map['bandGainsDb'];
    final bands = <int, double>{};
    if (rawBands is Map) {
      for (final e in rawBands.entries) {
        final key = int.tryParse(e.key.toString());
        final val = e.value is num ? (e.value as num).toDouble() : null;
        if (key != null && val != null) {
          bands[key] = val;
        }
      }
    }
    return EqualizerUserPreset(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Preset',
      preampDb: map['preampDb'] is num
          ? (map['preampDb'] as num).toDouble()
          : 0.0,
      bandGainsDb: bands,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] is num
            ? (map['createdAt'] as num).toInt()
            : DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] is num
            ? (map['updatedAt'] as num).toInt()
            : DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
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
