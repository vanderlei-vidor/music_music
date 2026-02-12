import 'package:flutter/material.dart';

import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/data/models/music_entity.dart';

class FolderCard extends StatelessWidget {
  final String folderName;
  final List<MusicEntity> musics;
  final VoidCallback onTap;

  const FolderCard({
    super.key,
    required this.folderName,
    required this.musics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = theme.extension<AppShadows>();
    final cardShadows = theme.brightness == Brightness.dark
        ? (shadows?.neumorphic ?? [])
        : (shadows?.elevated ?? []);

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'folder_$folderName',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: cardShadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // CAPA

                // OVERLAY
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),

                // TEXTO
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Text(
                        folderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${musics.length} mÃºsicas',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

