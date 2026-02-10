import 'package:flutter/material.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/features/home/widgets/folder_card.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/shared/widgets/skeleton.dart';

class FoldersView extends StatefulWidget {
  const FoldersView({super.key});

  @override
  State<FoldersView> createState() => _FoldersViewState();
}

class _FoldersViewState extends State<FoldersView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folders = context.watch<PlaylistViewModel>().folders;
    final folderPaths = folders.keys.toList()..sort();

    if (folderPaths.isEmpty) {
      return const _FoldersSkeleton();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: folderPaths.length,
      itemBuilder: (context, index) {
        final path = folderPaths[index];
        final musics = folders[path]!;
        final folderName = path.split('/').last;

        return AnimatedBuilder(
          animation: _controller,
          child: FolderCard(
            folderName: folderName,
            musics: musics,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.folderDetail,
                arguments: FolderDetailArgs(
                  folderName: folderName,
                  musics: musics,
                ),
              );
            },
          ),
          builder: (context, child) {
            final animation = CurvedAnimation(
              parent: _controller,
              curve: Interval(
                (index / folderPaths.length).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

class _FoldersSkeleton extends StatelessWidget {
  const _FoldersSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = theme.extension<AppShadows>()?.elevated ?? [];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                boxShadow: shadows,
              ),
              child: const Skeleton(
                width: double.infinity,
                height: 140,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),
            const Skeleton(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            const Skeleton(width: 80, height: 10),
          ],
        );
      },
    );
  }
}



