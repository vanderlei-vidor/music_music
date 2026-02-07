import 'package:flutter/material.dart';

import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/core/ui/genre_colors.dart';

class GenreCard extends StatelessWidget {
  final String genre;
  final int count;
  final VoidCallback onTap;

  const GenreCard({
    super.key,
    required this.genre,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = GenreColorHelper.getColor(genre);
    final shadows = theme.extension<AppShadows>();
    final cardShadows = theme.brightness == Brightness.dark
        ? (shadows?.neumorphic ?? [])
        : (shadows?.elevated ?? []);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.25), theme.colorScheme.surface],
          ),
          boxShadow: cardShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ICONE COM GLOW
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.6), blurRadius: 18),
                ],
              ),
              child: Icon(Icons.music_note, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            // NOME DO GENERO
            Expanded(
              child: Text(
                genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            // CONTAGEM
            Text(
              '$count músicas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
