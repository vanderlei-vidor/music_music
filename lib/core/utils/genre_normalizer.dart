






class GenreNormalizer {
  static String normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Desconhecido';
    }

    final g = raw.toLowerCase().trim();

    if (g.contains('rock')) return 'Rock';
    if (g.contains('pop')) return 'Pop';
    if (g.contains('classical') || g.contains('clássic')) return 'Clássica';
    if (g.contains('hip') || g.contains('rap')) return 'Hip Hop';
    if (g.contains('electro') || g.contains('dance')) return 'Eletrônica';
    if (g.contains('jazz')) return 'Jazz';
    if (g.contains('blues')) return 'Blues';
    if (g.contains('latin') || g.contains('latino')) return 'Latina';
    if (g.contains('reggae')) return 'Reggae';
    if (g.contains('metal')) return 'Metal';

    // fallback elegante
    return raw.trim().split('/').first.capitalize();
  }
}

extension _Cap on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
