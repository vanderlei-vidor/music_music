import 'package:flutter/material.dart';

import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/core/ui/genre_colors.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';

class GenreCard extends StatelessWidget {
  final String genre;
  final int count;
  final String? artworkUrl;
  final int? audioId;
  final VoidCallback onTap;

  const GenreCard({
    super.key,
    required this.genre,
    required this.count,
    this.artworkUrl,
    this.audioId,
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
            colors: [color.withValues(alpha: 0.25), theme.colorScheme.surface],
          ),
          boxShadow: cardShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child: ArtworkSquare(
                  artworkUrl: artworkUrl,
                  audioId: audioId,
                  borderRadius: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '$count musicas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
