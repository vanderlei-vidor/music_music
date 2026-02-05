import 'package:flutter/material.dart';
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
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎼 ÍCONE COM GLOW
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

            // 🎧 NOME DO GÊNERO
            Expanded(
              // Envolva em Expanded para ele não empurrar o resto pra fora
              child: Text(
                genre,
                maxLines:
                    1, // Reduzir para 1 linha ajuda a evitar overflow no Grid
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Force um tamanho menor se necessário
                ),
              ),
            ),

            

            // 🔢 CONTAGEM
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
